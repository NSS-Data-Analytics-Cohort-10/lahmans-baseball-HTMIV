-- 1. What range of years for baseball games played does the provided database cover? 

SELECT
CONCAT(MIN(CAST(SUBSTRING(DEBUT,1,4) AS INT)),' TO ', MAX(CAST(SUBSTRING(DEBUT,1,4) AS INT))) YEARS
FROM  
PEOPLE P;

-- 1871 TO 2017

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT 
 UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST) NAME,
 CONCAT(ROUND(CAST(P.HEIGHT/12 AS NUMERIC),2),' FT') HEIGHT,
 SUM(G_ALL) TOTAL_GAMES
FROM  
PEOPLE P
 INNER JOIN APPEARANCES A ON P.PLAYERID = A.PLAYERID
WHERE 
 P.HEIGHT IS NOT NULL AND P.HEIGHT IN (SELECT MIN(HEIGHT) FROM PEOPLE WHERE HEIGHT IS NOT NULL)
GROUP BY
 UPPER(P.NAMELAST)||', '||UPPER(NAMEFIRST),
 P.HEIGHT;

-- EDWARD CARL 
-- 3.58 FT  
-- 1

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH X AS (
SELECT 
 P.PLAYERID,
 UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST) NAME,
 CONCAT('FIRST GAME: ',MIN(P.DEBUT),' LAST GAME: ',MAX(P.FINALGAME))FIRST_LAST_GAME,
 UPPER(SC.SCHOOLNAME) SCHOOL_NAME
FROM  
 PEOPLE P
 INNER JOIN COLLEGEPLAYING CP ON CP.PLAYERID = P.PLAYERID
 INNER JOIN SCHOOLS SC ON CP.SCHOOLID = SC.SCHOOLID
WHERE 
 UPPER(SC.SCHOOLNAME) LIKE '%VANDERB%'
GROUP BY
 P.PLAYERID,
 UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST),
 UPPER(SC.SCHOOLNAME))
SELECT 
 X.NAME,
 X.FIRST_LAST_GAME,
 X.SCHOOL_NAME,
 Y.TOTAL_SALARY
FROM X
 INNER JOIN
 (SELECT 
 PLAYERID,
 CAST(SUM(CAST(SALARY AS NUMERIC ))AS MONEY) TOTAL_SALARY
  FROM SALARIES
 GROUP BY PLAYERID) Y ON X.PLAYERID = Y.PLAYERID
ORDER BY 4 DESC;

-- PRICE, DAVID - $81,851,296.00 
-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
   
SELECT 
 YEARID,
 CASE 
 WHEN POS = 'OF' THEN 'OUTFIELD'
 WHEN POS IN ('SS','1B','2B','3B') THEN 'INFIELD'
 WHEN POS IN('P','C') THEN 'BATTERY'
 END POSITIONS,
 SUM(PO) PUTOUTS
FROM 
 FIELDING
WHERE YEARID = 2016
GROUP BY
 YEARID,
 CASE 
 WHEN POS = 'OF' THEN 'OUTFIELD'
 WHEN POS IN ('SS','1B','2B','3B') THEN 'INFIELD'
 WHEN POS IN('P','C') THEN 'BATTERY'
 END
ORDER BY 2


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT 
 CONCAT(SUBSTRING(CAST(YEARID AS VARCHAR(4)),1,3),'0','s') DECADE,
-- SUM(G) TOTAL_GAMES,
 --SUM(SO) STRIKE_OUTS,
 ROUND(CAST(SUM(SO) AS NUMERIC)/CAST(SUM(G)AS NUMERIC),2) AVG_STRIKEOUT_PER_GAME,
-- SUM(HR) HRS,
 ROUND(CAST(SUM(HR) AS NUMERIC)/CAST(SUM(G)AS NUMERIC),2) AVG_HR_PER_GAME
FROM 
 TEAMS
GROUP BY
 CONCAT(SUBSTRING(CAST(YEARID AS VARCHAR(4)),1,3),'0','s')
ORDER BY 1


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	
WITH X AS (
SELECT
 PLAYER_NAME,
 STOLEN_SUCCESS,
 CAUGHT_STEALING,
 TOTAL_ATTEMPTS,
 CASE WHEN STOLEN_SUCCESS = 0 THEN 0
 ELSE (STOLEN_SUCCESS/TOTAL_ATTEMPTS)*100 END PERCENTAGE,
 RANK() OVER (ORDER BY  CASE WHEN STOLEN_SUCCESS = 0 THEN 0
 ELSE (STOLEN_SUCCESS/TOTAL_ATTEMPTS)*100 END DESC) RANKING
FROM
(SELECT
 B.PLAYERID,
 UPPER(NAMELAST||', '||NAMEFIRST) PLAYER_NAME,
 CAST(SUM(SB) AS NUMERIC) STOLEN_SUCCESS,
 CAST(SUM(CS) AS NUMERIC) CAUGHT_STEALING,
 CAST(SUM(SB)+SUM(CS) AS NUMERIC) TOTAL_ATTEMPTS
FROM 
 BATTING B
 INNER JOIN PEOPLE P ON B.PLAYERID = P.PLAYERID
WHERE 
 YEARID = 2016 
GROUP BY 
 B.PLAYERID,
 UPPER(NAMELAST||', '||NAMEFIRST))
 WHERE TOTAL_ATTEMPTS >= 20)
SELECT
 PLAYER_NAME,
 STOLEN_SUCCESS,
 CAUGHT_STEALING,
 TOTAL_ATTEMPTS,
 ROUND(PERCENTAGE,2) PERCENTAGE

FROM X WHERE RANKING = 1

-- "OWINGS, CHRIS", 91.30% SUCCESS RATE

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 

SELECT 'MOST_WINS_NO_WS_WIN' TYPE, * FROM 
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N'))
WHERE WS_WIN='N' AND WINS =
(SELECT
 MAX(WINS)
FROM(
SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 AND COALESCE(WSWIN,'N') ='N'
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')))
 UNION
 SELECT 'LEAST_WINS_WS_WIN' TYPE, * FROM 
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')) 
WHERE WS_WIN = 'Y' AND WINS =
(SELECT
 MIN(WINS)
FROM(
SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 AND COALESCE(WSWIN,'N') ='Y'
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')))
 
 ORDER BY 1 DESC

--"MOST_WINS_NO_WS_WIN"	2001	"SEA"	116	
--"LEAST_WINS_WS_WIN"	1981	"LAN"	63	

-- 7. PART 2 Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH X AS (
SELECT A.*
FROM(
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 AND YEARID <>
(SELECT YEARID FROM 
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')) 
WHERE WS_WIN = 'Y' AND WINS =
(SELECT
 MIN(WINS)
FROM(
SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 AND COALESCE(WSWIN,'N') ='Y'
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N'))))
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')
ORDER BY 1)) A
INNER JOIN
(SELECT
YEARID,
MAX(WINS) WINS
FROM
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 AND YEARID <>
(SELECT YEARID FROM 
(SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
 YEARID BETWEEN 1970 AND 2016 
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')) 
WHERE WS_WIN = 'Y' AND WINS =
(SELECT
 MIN(WINS)
FROM(
SELECT
 YEARID,
 TEAMID,
 SUM(W) WINS,
 COALESCE(WSWIN,'N') WS_WIN
FROM
 TEAMS 
WHERE
	--/*
 YEARID BETWEEN 1970 AND 2016 AND COALESCE(WSWIN,'N') ='Y'
	--*/
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N'))))
GROUP BY
 YEARID,
 TEAMID,
 COALESCE(WSWIN,'N')
ORDER BY 1)
GROUP BY YEARID) B ON A.YEARID = B.YEARID AND A.WINS = B.WINS)
SELECT 
 SUM(CASE
 WHEN WS_WIN = 'Y' THEN 1 ELSE 0
 END) COUNT_WS_WINS_MOST_WINS,
 COUNT(DISTINCT(YEARID)) COUNT_SEASONS,
 ROUND((CAST(SUM(CASE
 WHEN WS_WIN = 'Y' THEN 1 ELSE 0
 END) AS NUMERIC)/
 CAST(COUNT(DISTINCT(YEARID))AS NUMERIC))*100,2) PERCENTAGE
FROM X

-- 12 times out of 46 season
-- 26.09

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.




-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame??