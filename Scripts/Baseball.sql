-- 1. What range of years for baseball games played does the provided database cover? 

SELECT
CONCAT(MIN(CAST(SUBSTRING(DEBUT,1,4) AS INT)),' TO ', MAX(CAST(SUBSTRING(DEBUT,1,4) AS INT))) YEARS
FROM  
PEOPLE P;

-- 1871 TO 2017

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT 
 UPPER(T.NAME) TEAM_NAME, 
 UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST) NAME,
 CONCAT(ROUND(CAST(P.HEIGHT/12 AS NUMERIC),2),' FT') HEIGHT,
 SUM(G_ALL) TOTAL_GAMES
FROM  
PEOPLE P
 INNER JOIN APPEARANCES A ON P.PLAYERID = A.PLAYERID
 INNER JOIN TEAMS T ON A.TEAMID = T.TEAMID AND T.YEARID = A.YEARID
WHERE 
 P.HEIGHT IS NOT NULL AND P.HEIGHT IN (SELECT MIN(HEIGHT) FROM PEOPLE WHERE HEIGHT IS NOT NULL)
GROUP BY
 UPPER(T.NAME),
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
 ROUND(CAST(SUM(SO) AS NUMERIC)/CAST(SUM(G)AS NUMERIC)/2,2) AVG_STRIKEOUT_PER_GAME,
-- SUM(HR) HRS,
 ROUND(CAST(SUM(HR) AS NUMERIC)/CAST(SUM(G)AS NUMERIC)/2,2) AVG_HR_PER_GAME
FROM 
 TEAMS 
WHERE YEARID >1920
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

-- 12 times out of 46 seasons
-- 26.09

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


WITH X AS
(SELECT
 'HIGHEST TOP 5 ATTENDANCE' ATTENANCE_TYPE,
 UPPER(T.NAME) TEAM_NAME,
 UPPER(T.PARK)BAll_PARK,
 H.ATTENDANCE/H.GAMES AVG_ATTENDANCE,
 H.ATTENDANCE,
 H.GAMES,
 RANK() OVER (ORDER BY  H.ATTENDANCE/H.GAMES DESC) RANKING
FROM
 HOMEGAMES H
 INNER JOIN TEAMS T ON H.TEAM = T.TEAMID AND H.YEAR = T.YEARID
WHERE
 H.GAMES >=10 AND
 H.YEAR = 2016
UNION
SELECT
 'LOWEST TOP 5 ATTENDANCE' ATTENANCE_TYPE,
 UPPER(T.NAME) TEAM_NAME,
 UPPER(T.PARK)BAll_PARK,
 H.ATTENDANCE/H.GAMES AVG_ATTENDANCE,
 H.ATTENDANCE,
 H.GAMES,
 RANK() OVER (ORDER BY  H.ATTENDANCE/H.GAMES ASC) RANKING
FROM
 HOMEGAMES H
 INNER JOIN TEAMS T ON H.TEAM = T.TEAMID AND H.YEAR = T.YEARID
WHERE
 H.GAMES >=10 AND
 H.YEAR = 2016)
SELECT
 RANKING,
 ATTENANCE_TYPE,
 TEAM_NAME,
 BALL_PARK,
 AVG_ATTENDANCE
FROM X 
 WHERE 
 RANKING BETWEEN 1 AND 5
ORDER BY
 2,1


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT 
	 C.MANAGER_NAME,
	 R.YEARID,
	 L.TEAM,
     COALESCE(AL,NL) LEAGUE
FROM (
	SELECT 
	 PLAYERID,
	 YEARID,
	 CASE WHEN LGID ='AL' THEN 'AL' END  AL,
	 CASE WHEN LGID ='NL' THEN 'NL' END NL
	FROM 
	 AWARDSMANAGERS
	WHERE SUBSTRING(AWARDID,1,3) = 'TSN'
UNION
	SELECT 
	 PLAYERID,
	 YEARID,
	 CASE WHEN LGID ='AL' THEN 'AL' END  AL,
	 CASE WHEN LGID ='NL' THEN 'NL' END NL
	FROM 
	 AWARDSSHAREMANAGERS
	WHERE SUBSTRING(AWARDID,1,3) = 'TSN') R
INNER JOIN
	(SELECT 
	H.PLAYERID,
	E.MANAGER_NAME
	FROM (
	(SELECT
	 PLAYERID,
	 SUM(CASE WHEN AL = 'AL' THEN 1 ELSE 0 END) AMERICAN_LEAGUE,
	 SUM(CASE WHEN NL= 'NL' THEN 1 ELSE 0 END) NATIONAL_LEAGUE
	FROM (
	SELECT 
	 PLAYERID,
	 CASE WHEN LGID ='AL' THEN 'AL' END  AL,
	 CASE WHEN LGID ='NL' THEN 'NL' END NL
	FROM 
	 AWARDSMANAGERS
	WHERE SUBSTRING(AWARDID,1,3) = 'TSN'
	GROUP BY
	 PLAYERID,
	 CASE WHEN LGID ='AL' THEN 'AL' END,
	 CASE WHEN LGID ='NL' THEN 'NL' END
UNION 
	SELECT 
	 PLAYERID,
	 CASE WHEN LGID ='AL' THEN 'AL' END  AL,
	 CASE WHEN LGID ='NL' THEN 'NL' END NL
	FROM 
	 AWARDSSHAREMANAGERS
	WHERE SUBSTRING(AWARDID,1,3) = 'TSN'
	GROUP BY
	 PLAYERID,
	 CASE WHEN LGID ='AL' THEN 'AL' END,
	 CASE WHEN LGID ='NL' THEN 'NL' END)
	GROUP BY PLAYERID) H
INNER JOIN 
	(SELECT 
	 PLAYERID, 
	 UPPER(NAMEFIRST)||', '||UPPER(NAMELAST) MANAGER_NAME 
	 FROM PEOPLE) E ON H.PLAYERID = E.PLAYERID)
	WHERE H.AMERICAN_LEAGUE > 0 AND H.NATIONAL_LEAGUE > 0) C ON R.PLAYERID = C.PLAYERID
INNER JOIN 
	(SELECT * FROM MANAGERS) U ON R.PLAYERID = U.PLAYERID AND R.YEARID = U.YEARID 
INNER JOIN (SELECT TEAMID,YEARID,UPPER(NAME)TEAM FROM TEAMS) L ON U.TEAMID = L.TEAMID AND U.YEARID = L.YEARID
ORDER BY 1,2

SELECT * FROM PEOPLE WHERE UPPER(NAMELAST) ='MELVIN'
--melvibo01

/*
select awardid, yearid,lgid,'AWARDSSHAREMANAGERS' from AWARDSSHAREMANAGERS where playerid = 'melvibo01'
union
select awardid, yearid,lgid,'AWARDSMANAGERS' type  from AWARDSMANAGERS where playerid = 'melvibo01'
*/

--DAVEY, JOHNSON	1997	BALTIMORE ORIOLES 		AL
--DAVEY, JOHNSON	2012	WASHINGTON NATIONALS	NL
--JIM, LEYLAND		1988	PITTSBURGH PIRATES		NL
--JIM, LEYLAND		1990	PITTSBURGH PIRATES		NL
--JIM, LEYLAND		1992	PITTSBURGH PIRATES		NL
--JIM, LEYLAND		2006	DETROIT TIGERS"	    	AL

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


WITH X AS (
	SELECT D.*,E.* FROM (
	(SELECT 
		B.PLAYER_NAME,
		B.PLAYERID,
		A.YEARID,
		SUM(A.HR) HR
	FROM(
	(SELECT * FROM BATTING) A
INNER JOIN 
	(SELECT
		PLAYERID,
		PLAYER_NAME,
		MIN_YEAR,
		DEBUT_YEAR,
		MAX_YEAR,
		FINAL_YEAR,
		MAX_YEAR+1-MIN_YEAR YEARS_IN_LEAGUE,
		YEARS_PLAYING
	FROM(
	SELECT
		MIN(B.YEARID) MIN_YEAR,
		MAX(B.YEARID) MAX_YEAR,
		DEBUT,
		CAST(SUBSTRING(P.DEBUT,1,4) AS NUMERIC) DEBUT_YEAR,
		CAST(SUBSTRING(P.FINALGAME,1,4) AS NUMERIC)FINAL_YEAR,
		COUNT(DISTINCT YEARID) YEARS_PLAYING,
		B.PLAYERID,
		UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST) PLAYER_NAME
	FROM 
		BATTING B
		INNER JOIN PEOPLE P ON B.PLAYERID = P.PLAYERID
	GROUP BY
		P.DEBUT,
		P.FINALGAME,
		B.PLAYERID,
		UPPER(P.NAMELAST)||', '||UPPER(P.NAMEFIRST))
	WHERE
		YEARS_PLAYING >= 10) B ON B.PLAYERID = A.PLAYERID AND A.HR >=1 AND A.YEARID = 2016)
	GROUP BY
		B.PLAYERID,
		A.YEARID,
		B.PLAYER_NAME) D

INNER JOIN 
(SELECT
	PLAYERID,
	MAX(HR) MAX_HR FROM(
	SELECT 
		B.PLAYERID,
		A.YEARID,
		SUM(A.HR) HR
	FROM(
(SELECT * FROM BATTING) A
INNER JOIN 
	(SELECT
		PLAYERID,
		PLAYER_NAME,
		MIN_YEAR,
		DEBUT_YEAR,
		MAX_YEAR,
		FINAL_YEAR,
		MAX_YEAR+1-MIN_YEAR YEARS_IN_LEAGUE,
		YEARS_PLAYING
	FROM(
	SELECT
		MIN(B.YEARID) MIN_YEAR,
		MAX(B.YEARID) MAX_YEAR,
		DEBUT,
		CAST(SUBSTRING(P.DEBUT,1,4) AS NUMERIC) DEBUT_YEAR,
		CAST(SUBSTRING(P.FINALGAME,1,4) AS NUMERIC)FINAL_YEAR,
		COUNT(DISTINCT YEARID) YEARS_PLAYING,
		B.PLAYERID,
		UPPER(P.NAMEFIRST)||', '||UPPER(P.NAMELAST) PLAYER_NAME
	FROM 
		BATTING B
		INNER JOIN PEOPLE P ON B.PLAYERID = P.PLAYERID
	GROUP BY
		P.DEBUT,
		P.FINALGAME,
		B.PLAYERID,
		UPPER(P.NAMEFIRST)||', '||UPPER(P.NAMELAST))
	WHERE
		YEARS_PLAYING >= 10) B ON B.PLAYERID = A.PLAYERID AND A.HR >=1)
	GROUP BY
		B.PLAYERID,
		A.YEARID,
		B.PLAYER_NAME)
	GROUP BY PLAYERID) E ON D.PLAYERID = E.PLAYERID))
	SELECT YEARID,PLAYER_NAME,HR FROM X WHERE HR >= MAX_HR
ORDER BY 3 DESC, 1

--2016	"ENCARNACION, EDWIN"	42
--2016	"CANO, ROBINSON"		39
--2016	"NAPOLI, MIKE"			34
--2016	"UPTON, JUSTIN"			31
--2016	"PAGAN, ANGEL"			12
--2016	"DAVIS, RAJAI"			12
--2016	"WAINWRIGHT, ADAM"		2
--2016	"LIRIANO, FRANCISCO"	1
--2016	"COLON, BARTOLO"		1

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

WITH X AS (

SELECT
A.YEARID,
UPPER(B.NAME) TEAM_NAME,
A.AVG_SALARY,
RANK() OVER (PARTITION BY A.YEARID ORDER BY A.AVG_SALARY DESC ) RANK_SALARY,
B.W WINS,
RANK() OVER (PARTITION BY A.YEARID ORDER BY B.W DESC ) RANK_WINS
FROM
(SELECT 
	YEARID,
	TEAMID,
	CAST(ROUND(CAST(AVG(salary)AS NUMERIC),2)AS MONEY) AVG_SALARY
FROM
	SALARIES S
WHERE 
	YEARID >= 2000
GROUP BY 
	YEARID,
	TEAMID) A
INNER JOIN 
(SELECT * FROM TEAMS) B ON A.TEAMID = B.TEAMID AND A.YEARID = B.YEARID

ORDER BY 1,5 DESC)

SELECT * FROM X WHERE RANK_WINS BETWEEN 1 AND 10


-- 12. In this question, you will explore the connection between number of wins and attendance.
--       <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being          a division winner or a wild card winner.</li>
--     </ol>
SELECT
	TEAM_NAME,
	SUM(WINS) TOTAL_WINS,
	RANK() OVER (ORDER BY SUM(WINS) DESC) RANK_TOTAL_WINS,
	ROUND(AVG(ATTENDANCE),0) AVG_ATTENDANCE,
	RANK() OVER (ORDER BY ROUND(AVG(ATTENDANCE),0) DESC) RANK_AVG_ATTENDANCE
FROM(
	SELECT
	A.YEAR,
	UPPER(B.NAME) TEAM_NAME, 
	B.WINS,
	A.ATTENDANCE
FROM(
SELECT
	TEAM,
	YEAR,
	SUM(GAMES) GAMES,
	SUM(ATTENDANCE) ATTENDANCE
FROM
	HOMEGAMES
GROUP BY
	TEAM,
	YEAR
) A
INNER JOIN
(
SELECT 
	YEARID,
	TEAMID,
	NAME,
	SUM(W) WINS 
FROM TEAMS
GROUP BY
	YEARID,
	TEAMID,
	NAME
   ) B ON A.TEAM = B.TEAMID AND A.YEAR = B.YEARID AND A.ATTENDANCE <> 0)
 GROUP BY TEAM_NAME 
/*
Does there appear to be any correlation between attendance at home games and number of wins?
*/
-- NO DIRECT CORRELATION

-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being          a division winner or a wild card winner 

WITH X AS(
SELECT
	A.YEAR,
	UPPER(B.NAME) TEAM_NAME, 
	B.WINS,
	A.ATTENDANCE,
	B.WSWIN,
	COALESCE(CAST(LEAD(YEAR) OVER (PARTITION BY UPPER(B.NAME) ORDER BY YEAR ASC ) AS VARCHAR(4)),'N/A') YEAR_AFTER_WSWIN ,
	COALESCE(LEAD(A.ATTENDANCE) OVER (PARTITION BY UPPER(B.NAME) ORDER BY YEAR ASC ),0) ATTENDANCE_AFTER_WSWIN 
FROM(
SELECT
	TEAM,
	YEAR,
	SUM(GAMES) GAMES,
	SUM(ATTENDANCE) ATTENDANCE
FROM
	HOMEGAMES
GROUP BY
	TEAM,
	YEAR
) A
INNER JOIN
(
SELECT 
	YEARID,
	TEAMID,
	NAME,
	SUM(W) WINS, 
	WSWIN 
FROM TEAMS WHERE WSWIN IS NOT NULL
GROUP BY
	YEARID,
	TEAMID,
	NAME,
	WSWIN 
   ) B ON A.TEAM = B.TEAMID AND A.YEAR = B.YEARID AND A.ATTENDANCE <> 0)
SELECT
	--/*
	YEAR,
	TEAM_NAME,
	ATTENDANCE,
	WSWIN,
	YEAR_AFTER_WSWIN,
	ATTENDANCE_AFTER_WSWIN,
	--/*
	CASE 
	WHEN YEAR_AFTER_WSWIN = 'N/A' THEN YEAR_AFTER_WSWIN
	WHEN ATTENDANCE_AFTER_WSWIN = ATTENDANCE THEN 'NO CHANGE'
	WHEN ATTENDANCE_AFTER_WSWIN > ATTENDANCE THEN 'INCREASE'
	WHEN ATTENDANCE_AFTER_WSWIN < ATTENDANCE THEN 'DECREASE'
	END FOLLOWING_YEAR_STATUS
	/*
	COUNT(CASE 
	WHEN YEAR_AFTER_WSWIN = 'N/A' THEN YEAR_AFTER_WSWIN
	WHEN ATTENDANCE_AFTER_WSWIN = ATTENDANCE THEN 'NO CHANGE'
	WHEN ATTENDANCE_AFTER_WSWIN > ATTENDANCE THEN 'INCREASE'
	WHEN ATTENDANCE_AFTER_WSWIN < ATTENDANCE THEN 'DECREASE'
	END)
	*/
FROM X WHERE WSWIN = 'Y'	
/*
GROUP BY CASE 
	WHEN YEAR_AFTER_WSWIN = 'N/A' THEN YEAR_AFTER_WSWIN
	WHEN ATTENDANCE_AFTER_WSWIN = ATTENDANCE THEN 'NO CHANGE'
	WHEN ATTENDANCE_AFTER_WSWIN > ATTENDANCE THEN 'INCREASE'
	WHEN ATTENDANCE_AFTER_WSWIN < ATTENDANCE THEN 'DECREASE'
	END
*/
ORDER BY 1

--- 57 TEAMS SEE AN INCREASE
--- 51 TEAMS SEE A DECREASE
--- THERE WAS NOT A VALUE FOR 2016 SINCE THE DATA ONLY GOES TO 2016

--What about teams that made the playoffs? Making the playoffs means either being  a division winner or a wild card winner 

WITH X AS (
	SELECT 
		YEARID,
		COALESCE(CAST(LEAD(YEARID) OVER (PARTITION BY UPPER(NAME) ORDER BY YEARID ASC ) AS VARCHAR(4)),'N/A') FOLLOWING_YEAR,
		TEAMID,
		LEAD(TEAMID) OVER (PARTITION BY UPPER(NAME)) TEAM_LEAD,
		UPPER(NAME) TEAM_NAME,
		CASE WHEN (COALESCE(DIVWIN,'N') ='Y' OR COALESCE(WCWIN,'N') ='Y') THEN 'YES' ELSE 'NO' END MADE_PLAYOFFS
	FROM TEAMS --WHERE (COALESCE(DIVWIN,'N') ='Y' OR COALESCE(WCWIN,'N') ='Y')
	GROUP BY
		YEARID,
		TEAMID,
		NAME,
		CASE WHEN (COALESCE(DIVWIN,'N') ='Y' OR COALESCE(WCWIN,'N') ='Y') THEN 'YES' ELSE 'NO' END
	ORDER BY 2,1
)
	SELECT 
	    /*
		X.YEARID,
		X.FOLLOWING_YEAR,
		X.TEAMID,
		X.TEAM_LEAD,
		X.TEAM_NAME,
		X.MADE_PLAYOFFS,
		Y.ATTENDANCE,
		Z.ATTENDANCE_NEXT_YEAR,
		*/
		CASE 
		WHEN Y.ATTENDANCE = Z.ATTENDANCE_NEXT_YEAR THEN 'NO DELTA'
		WHEN Y.ATTENDANCE > Z.ATTENDANCE_NEXT_YEAR THEN 'DECREASE'
		WHEN Y.ATTENDANCE < Z.ATTENDANCE_NEXT_YEAR THEN 'INCREASE'
		END FOLLOWING_YEAR_STATUS,
		COUNT(CASE 
		WHEN Y.ATTENDANCE = Z.ATTENDANCE_NEXT_YEAR THEN 'NO DELTA'
		WHEN Y.ATTENDANCE > Z.ATTENDANCE_NEXT_YEAR THEN 'DECREASE'
		WHEN Y.ATTENDANCE < Z.ATTENDANCE_NEXT_YEAR THEN 'INCREASE'
		END)
	FROM X
	
INNER JOIN 
	(SELECT YEAR, TEAM, SUM(ATTENDANCE) ATTENDANCE FROM HOMEGAMES  GROUP BY YEAR, TEAM) Y 
	ON X.YEARID = Y.YEAR AND X.TEAMID = Y.TEAM
INNER JOIN 
    (SELECT CAST(YEAR AS VARCHAR(10)) AS YEAR, TEAM, SUM(ATTENDANCE) ATTENDANCE_NEXT_YEAR FROM HOMEGAMES  GROUP BY YEAR, TEAM) Z
	ON X.FOLLOWING_YEAR = Z.YEAR AND X.TEAM_LEAD = Z.TEAM
WHERE 
	MADE_PLAYOFFS = 'YES' AND FOLLOWING_YEAR <> 'N/A'
	
	GROUP BY CASE 
		WHEN Y.ATTENDANCE = Z.ATTENDANCE_NEXT_YEAR THEN 'NO DELTA'
		WHEN Y.ATTENDANCE > Z.ATTENDANCE_NEXT_YEAR THEN 'DECREASE'
		WHEN Y.ATTENDANCE < Z.ATTENDANCE_NEXT_YEAR THEN 'INCREASE'
		END

--DECREASE ATTENDANCE 	113 TIMES
--INCREASE ATTENDANCE 	166 TIMES


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame??
/*
SELECT * FROM PITCHING;
SELECT PLAYERID FROM PITCHING GROUP BY PLAYERID HAVING COUNT (PLAYERID) > 1;
SELECT * FROM PEOPLE;
SELECT PLAYERID FROM PEOPLE GROUP BY PLAYERID HAVING COUNT (PLAYERID) > 1;
*/


-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers.

SELECT
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) RHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) LLHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) TOTAL_PITCHERS,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_RHP,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_LHP
FROM PITCHING P
INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID

-- RHP 				6605
-- RHP% 			72.73
-- LHP 				2477
-- LHP% 			27.27
-- TOTAL PTICHERS	2477 

/*
SELECT * FROM (
SELECT 
P.PLAYERID 
FROM 
	PITCHING P
    INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID
WHERE 
	P1.THROWS ='R'
GROUP
BY P.PLAYERID) T
WHERE EXISTS
(SELECT 
P3.PLAYERID 
FROM 
	PITCHING P2
    INNER JOIN PEOPLE P3 ON P2.PLAYERID =P3.PLAYERID
WHERE 
	P3.THROWS ='L' AND P3.PLAYERID = T.PLAYERID
GROUP
BY P3.PLAYERID)
*/
/*
SELECT
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) RHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) LLHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) TOTAL_PITCHERS,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_RHP,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_LHP
FROM 
	PITCHING P
	INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID
*/
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame??
--SELECT UPPER(AWARDID) AWARDID FROM AWARDSPLAYERS GROUP BY AWARDID  ORDER BY 1;

WITH X AS (
SELECT
    'CY YOUNG AWARD' AWARD,
    COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) RHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) LLHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) TOTAL_PITCHERS,
	ROUND(CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))AS NUMERIC)/
	CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)*100,2) RHP_AWARD,
	ROUND(CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))AS NUMERIC)/
	CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)*100,2) LHP_AWARD
FROM
    PITCHING P
	INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID
	INNER JOIN APPEARANCES A ON A.PLAYERID = P1.PLAYERID
	INNER JOIN AWARDSPLAYERS AP ON A.PLAYERID = AP.PLAYERID
WHERE
   SUBSTRING(UPPER(AP.AWARDID),1,2) ='CY' AND A.G_ALL <> 0
UNION
SELECT
    'HALL OF FAME' AWARD,
    COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) RHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) LLHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) TOTAL_PITCHERS,
	ROUND(CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))AS NUMERIC)/
	CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)*100,2) RHP_AWARD,
	ROUND(CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))AS NUMERIC)/
	CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)*100,2) LHP_AWARD
FROM
    PITCHING P
	INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID
	INNER JOIN APPEARANCES A ON A.PLAYERID = P1.PLAYERID
	INNER JOIN HALLOFFAME AP ON A.PLAYERID = AP.PLAYERID
WHERE
   AP.INDUCTED ='Y' AND A.G_ALL <> 0
UNION
SELECT
    'SUMMARY OF PITCHERS' AWARD,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) RHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) LLHP,
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) TOTAL_PITCHERS,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_RHP,
	ROUND((CAST(COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END)) AS NUMERIC)/
	CAST((COUNT(DISTINCT(CASE WHEN P1.THROWS ='R' THEN P.PLAYERID END))+
	COUNT(DISTINCT(CASE WHEN P1.THROWS ='L' THEN P.PLAYERID END))) AS NUMERIC))*100,2) PERCENT_LHP
FROM PITCHING P
INNER JOIN PEOPLE P1 ON P.PLAYERID =P1.PLAYERID)

SELECT * FROM X ORDER BY 3

-- LHP AWARD WINNERS ARE PROPORTIONATE TO THE AMOUNT OF LHP IN THE DATA
