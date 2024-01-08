
SELECT *
FROM cs_go..matcheco

SELECT *
FROM cs_go..matchid

SELECT *
FROM cs_go..matchinfo

SELECT *
FROM cs_go..matchmap

SELECT *
FROM cs_go..matchoverview

SELECT *
FROM cs_go..player

SELECT *
FROM cs_go..team

/*Delete index column 'F1', forgot to drop it before extracting from pandas dataframe to excel file. Beginner mistake :D*/
ALTER TABLE cs_go..team
DROP COLUMN F1

/*Player Table*/

SELECT *
FROM cs_go..player

--QUESTION 1: WHICH COUNTRY HAS THE MOST PLAYERS
SELECT Country, COUNT(Country) AS PLAYER_COUNT
FROM cs_go..player
GROUP BY Country
ORDER BY 2 DESC

/*Team Table*/

SELECT *
FROM cs_go..team

--QUESTION 2: WHICH COUNTRY HAS THE MOST TEAMS
SELECT Country, COUNT(Country) AS TEAM_COUNT
FROM cs_go..team
GROUP BY Country
ORDER BY 2 DESC

/*Match Id Table*/

--JUST TITTLE :D, NAME OF MATCHES BETWEEN TEAMS
SELECT *
FROM cs_go..matchid

/*Match Map Table*/

SELECT *
FROM cs_go..matchmap

--QUESTION 3: WHICH MAPS FREQUENTLY APPEAR IN THE MATCH
SELECT MapName, COUNT(MapName) AS MAP_COUNT
FROM cs_go..matchmap
GROUP BY MapName
ORDER BY 2 DESC

--QUESTION 4: WHICH MATCH PLAY THE MOST MAP
SELECT Tittle, mm.MatchID, COUNT(MapName) AS MAP_COUNT
FROM cs_go..matchmap mm
JOIN cs_go..matchid mi
ON mm.MatchID = mi.ID
GROUP BY mm.MatchID, Tittle
ORDER BY 3 DESC

/*Match Overview Table*/ 

SELECT * 
FROM cs_go..matchoverview 

--QUESTION 5: ON EACH MAP IN THE MATCH, HOW MANY PICKS ARE TAKEN BY EACH TEAM
WITH CTE (MapName, Team1_Pick, Team2_Pick) AS
	(--CREATE VIEW MO_PICK AS
	SELECT MapName, [1] AS Team1_Pick, [2] AS Team2_Pick
	FROM
		(SELECT MapName,
		CASE
			WHEN Team1_Pick = 1 THEN 1
			WHEN Team1_Pick = 0 THEN 2
		END AS Team_Pick
		FROM cs_go..matchoverview mo
		JOIN cs_go..matchmap mm
			ON mo.MapID = mm.MapID) AS SQ
	PIVOT
		(COUNT(Team_Pick)
		FOR Team_Pick
		IN([1],[2])) AS PT
	UNION
	SELECT *
	FROM
		(SELECT 'TOTAL' AS MapName,
		CASE
			WHEN Team1_Pick = 1 THEN 1
			WHEN Team1_Pick = 0 THEN 2
		END AS Team_Pick
		FROM cs_go..matchoverview mo
		JOIN cs_go..matchmap mm
			ON mo.MapID = mm.MapID) AS SQ
	PIVOT
		(COUNT(Team_Pick)
		FOR Team_Pick
		IN([1],[2])) AS PT)
SELECT *, 
CASE WHEN MapName = 'TOTAL' THEN '-'
	ELSE (Team1_Pick+Team2_Pick)
END AS TOTAL
	FROM CTE
ORDER BY 4 DESC

--Q6: ON EACH MAP IN THE MATCH, HOW MANY WINS ARE TAKEN EACH TEAM GET
WITH CTE (MapName, Team1_Win, Team2_Win) AS
	(--CREATE VIEW MO_WIN AS
	SELECT MapName, [1] AS Team1_Win, [2] AS Team2_Win
	FROM
		(SELECT MapName,
		CASE
			WHEN Team1_Win = 1 THEN 1
			WHEN Team1_Win = 0 THEN 2
		END AS Team_Win
		FROM cs_go..matchoverview mo
		JOIN cs_go..matchmap mm
			ON mo.MapID = mm.MapID) AS SQ
	PIVOT
		(COUNT(Team_Win)
		FOR Team_Win
		IN([1],[2])) AS PT
	UNION
	SELECT *
	FROM
		(SELECT 'TOTAL' AS MapName,
		CASE
			WHEN Team1_Win = 1 THEN 1
			WHEN Team1_Win = 0 THEN 2
		END AS Team_Win
		FROM cs_go..matchoverview mo
		JOIN cs_go..matchmap mm
			ON mo.MapID = mm.MapID) AS SQ
	PIVOT
		(COUNT(Team_Win)
		FOR Team_Win
		IN([1],[2])) AS PT)
SELECT *, 
CASE WHEN MapName = 'TOTAL' THEN '-'
	ELSE (Team1_Win+Team2_Win)
END AS TOTAL
	FROM CTE
ORDER BY 4 DESC

--Q7: HOW MUCH THE FIRST PICK INFLUENCES WINNING

SELECT *
FROM cs_go..MO_PICK

SELECT *
FROM cs_go..MO_WIN

SELECT MP.MapName, Team1_Pick, Team2_Pick, Team1_Win, Team2_Win, 
ROUND(CAST(Team1_Win AS float)/Team1_Pick*100,2) AS T1_WIN_PCT,
ROUND(CAST(Team2_Win AS float)/Team2_Pick*100,2) AS T2_WIN_PCT
FROM cs_go..MO_PICK MP
JOIN cs_go..MO_WIN MW
	ON MP.MapName = MW.MapName
ORDER BY 2

--Q8: WHICH MATCH HAS THE EASIEST SCORING
--CREATE VIEW EZ_SCORE AS
SELECT DISTINCT mo.MatchID, Tittle, mo.MapID, MapName, 
Team1, t1.Name AS T1_NAME, Team1_Final_Score, 
Team2, t2.Name AS T2_NAME, Team2_Final_Score,
(ABS(Team1_Final_Score-Team2_Final_Score)) AS DIFF
FROM cs_go..matchoverview mo
JOIN cs_go..matchmap mm
	ON mo.MapID = mm.MapID
JOIN cs_go..matchid mi
	ON mo.MatchID = mi.ID
JOIN cs_go..team t1
	ON mo.Team1 = t1.ID
JOIN cs_go..team t2
	ON mo.Team2 = t2.ID
WHERE Team1_OT_Score = 0 OR Team2_OT_Score = 0
ORDER BY 11 DESC

--Q9: WHICH MAP HAS THE MOST EASIEST SCORING COUNT
SELECT MapName, COUNT(DIFF) AS DIFF_COUNT
FROM cs_go..EZ_SCORE
GROUP BY MapName
ORDER BY 2 DESC

--Q10: WHICH MATCH HAS THE MOST DIFFICULT SCORING UNTIL OVERTIME
--CREATE VIEW HAR_SCORE AS
SELECT DISTINCT mo.MatchID, Tittle, mo.MapID, MapName, 
Team1, t1.Name AS T1_NAME, Team1_Final_Score, 
Team2, t2.Name AS T2_NAME, Team2_Final_Score,
(ABS(Team1_Final_Score-Team2_Final_Score)) AS DIFF
FROM cs_go..matchoverview mo
JOIN cs_go..matchmap mm
	ON mo.MapID = mm.MapID
JOIN cs_go..matchid mi
	ON mo.MatchID = mi.ID
JOIN cs_go..team t1
	ON mo.Team1 = t1.ID
JOIN cs_go..team t2
	ON mo.Team2 = t2.ID
WHERE Team1_OT_Score > 0 AND Team2_OT_Score > 0
ORDER BY 11

--Q11: WHICH MAP HAS THE MOST HARDEST SCORING COUNT
SELECT MapName, COUNT(DIFF) AS DIFF_COUNT
FROM cs_go..HAR_SCORE
GROUP BY MapName
ORDER BY 2 DESC

--Q12: OVERALL MATCH RESULTS
WITH EZ (MapName, EZ_DIFF_COUNT) AS 
	(SELECT MapName, COUNT(DIFF) AS EZ_DIFF_COUNT
	FROM cs_go..EZ_SCORE
	GROUP BY MapName),
	HAR (MapName, HAR_DIFF_COUNT) AS
	(SELECT MapName, COUNT(DIFF) AS HAR_DIFF_COUNT
	FROM cs_go..HAR_SCORE
	GROUP BY MapName),
	TOTAL (MapName, TOTAL) AS 
	(SELECT EZ.MapName, EZ_DIFF_COUNT+HAR_DIFF_COUNT AS TOTAL
	FROM EZ
	JOIN HAR
		ON EZ.MapName = HAR.MapName)
SELECT EZ.MapName, EZ_DIFF_COUNT, HAR_DIFF_COUNT, TOTAL
FROM EZ
JOIN HAR
	ON EZ.MapName = HAR.MapName
JOIN TOTAL
	ON EZ.MapName = TOTAL.MapName
UNION
SELECT 'TOTAL' AS MapName,
SUM(EZ_DIFF_COUNT), SUM(HAR_DIFF_COUNT), '-' AS TOTAL
FROM EZ
JOIN HAR
	ON EZ.MapName = HAR.MapName
JOIN TOTAL
	ON EZ.MapName = TOTAL.MapName
ORDER BY 4 DESC

/*Match Info Table*/

SELECT *
FROM cs_go..matchinfo

--Q13: PLAYER WITH THE HIGHEST TOTAL AVERAGE DAMAGE PER ROUND
SELECT PlayerID, NAME, Country, TeamID, Total_ADR
FROM
	(SELECT mn.PlayerID, p.Name, Country, TeamID, Total_ADR,
	MAX(Total_ADR) OVER (PARTITION BY TeamID) AS MAX_ADR
	FROM cs_go..matchinfo mn
	JOIN cs_go..player p
		ON mn.PlayerID = p.ID) SQ
WHERE Total_ADR = MAX_ADR
ORDER BY 5 DESC

--Q14: PLAYER WITH THE HIGHEST TOTAL PERCENTAGE OF ROUNDS IN WHICH THE PLAYER EITHER HAD A KILL, ASSIST, SURVIVED OR WAS TRADED
SELECT DISTINCT PlayerID, NAME, Country, TeamID, Total_KAST
FROM
	(SELECT mn.PlayerID, p.Name, Country, TeamID, Total_KAST,
	MAX(Total_KAST) OVER (PARTITION BY TeamID) AS MAX_KAST
	FROM cs_go..matchinfo mn
	JOIN cs_go..player p
		ON mn.PlayerID = p.ID) SQ
WHERE Total_KAST = MAX_KAST
ORDER BY 5 DESC

--Q15: PLAYERS WITH THE HIGHEST TOTAL RATING
SELECT DISTINCT PlayerID, NAME, Country, TeamID, Total_Rating
FROM
	(SELECT mn.PlayerID, p.Name, Country, TeamID, Total_Rating,
	MAX(Total_Rating) OVER (PARTITION BY TeamID) AS MAX_RATING
	FROM cs_go..matchinfo mn
	JOIN cs_go..player p
		ON mn.PlayerID = p.ID) SQ
WHERE Total_Rating = MAX_RATING
ORDER BY 5 DESC

--Q16: NUMBER OF PLAYERS AND TEAMS WITH TOTAL RATING ABOVE THE AVERAGE BY EACH COUNTRY
WITH CTE (PlayerID, Country, TeamID, Total_Rating, AVG_RATE) AS
	(SELECT PlayerID, Country, TeamID, Total_Rating, ROUND(SUM_RATE/COUNT_RATE,2) AS AVG_RATE
	FROM
		(SELECT PlayerID, Country, TeamID, Total_Rating,
		SUM(Total_Rating) OVER (PARTITION BY Country) AS SUM_RATE,
		COUNT(Total_Rating) OVER (PARTITION BY Country) AS COUNT_RATE
		FROM cs_go..matchinfo mn
		JOIN cs_go..player p
			ON mn.PlayerID = p.ID
		) SQ
	WHERE (SUM_RATE/COUNT_RATE) < Total_Rating
	)
SELECT Country, AVG_RATE, COUNT(DISTINCT TeamID) AS TEAM_COUNT, 
COUNT(DISTINCT PlayerID) AS PLAYER_COUNT
FROM CTE
GROUP BY Country, AVG_RATE
ORDER BY 3 DESC

--Q17: NUMBER OF PLAYERS AND TEAMS WITH CT RATING ABOVE THE AVERAGE BY EACH COUNTRY
WITH CTE (PlayerID, Country, TeamID, CT_Rating, AVG_RATE) AS
	(SELECT PlayerID, Country, TeamID, CT_Rating, ROUND(SUM_RATE/COUNT_RATE,2) AS AVG_RATE
	FROM
		(SELECT PlayerID, Country, TeamID, CT_Rating,
		SUM(CT_Rating) OVER (PARTITION BY Country) AS SUM_RATE,
		COUNT(CT_Rating) OVER (PARTITION BY Country) AS COUNT_RATE
		FROM cs_go..matchinfo mn
		JOIN cs_go..player p
			ON mn.PlayerID = p.ID
		) SQ
	WHERE (SUM_RATE/COUNT_RATE) < CT_Rating
	)
SELECT Country, AVG_RATE, COUNT(DISTINCT TeamID) AS TEAM_COUNT, 
COUNT(DISTINCT PlayerID) AS PLAYER_COUNT
FROM CTE
GROUP BY Country, AVG_RATE
ORDER BY 3 DESC

--Q18: NUMBER OF PLAYERS AND TEAMS WITH TR RATING ABOVE THE AVERAGE BY EACH COUNTRY
WITH CTE (PlayerID, Country, TeamID, TR_Rating, AVG_RATE) AS
	(SELECT PlayerID, Country, TeamID, TR_Rating, ROUND(SUM_RATE/COUNT_RATE,2) AS AVG_RATE
	FROM
		(SELECT PlayerID, Country, TeamID, TR_Rating,
		SUM(TR_Rating) OVER (PARTITION BY Country) AS SUM_RATE,
		COUNT(TR_Rating) OVER (PARTITION BY Country) AS COUNT_RATE
		FROM cs_go..matchinfo mn
		JOIN cs_go..player p
			ON mn.PlayerID = p.ID
		) SQ
	WHERE (SUM_RATE/COUNT_RATE) < TR_Rating
	)
SELECT Country, AVG_RATE, COUNT(DISTINCT TeamID) AS TEAM_COUNT, 
COUNT(DISTINCT PlayerID) AS PLAYER_COUNT
FROM CTE
GROUP BY Country, AVG_RATE
ORDER BY 3 DESC

--Q19: NUMBER OF PLAYERS WHO ARE SUPERIOR IN THE POSITION OF CT OR TR IN EACH COUNTRY
WITH CTE (Country, CT, TR) AS
	(SELECT Country, CT, TR
	FROM
		(SELECT Country, 
		CASE WHEN AVG_CT_RATE > AVG_TR_RATE THEN 'CT' ELSE 'TR' END AS SIDE
		FROM
			(SELECT PlayerID, TeamID, 
			ROUND(AVG(CT_Rating),2) AS AVG_CT_RATE, 
			ROUND(AVG(TR_Rating),2) AS AVG_TR_RATE
			FROM cs_go..matchinfo
			GROUP BY PlayerID, TeamID) SQ
		JOIN cs_go..player p
			ON SQ.PlayerID = p.ID
				) SQ1
	PIVOT(COUNT(SIDE)
		FOR SIDE IN ([CT], [TR])) PVT
	)
SELECT *, (CT+TR) AS TOTAL
FROM CTE
ORDER BY 4 DESC

/* Match Eco Table*/

SELECT *
FROM cs_go..matcheco

--Q20: TEAM WITH INCREASING WINNING PERCENTAGE EACH ROUND

SELECT *
FROM cs_go..matcheco

WITH CTE (TeamID, Name, ECO_RND_PCT, SECO_RND_PCT, SBUY_RND_PCT, FBUY_RND_PCT) AS
	(SELECT TeamID, Name,
	ROUND(NULLIF(AVG_ECO_WON, 0)/AVG_ECO_RND,2) AS ECO_RND_PCT,
	ROUND(NULLIF(AVG_SECO_WON, 0)/AVG_SECO_RND,2) AS SECO_RND_PCT,
	ROUND(NULLIF(AVG_SBUY_WON, 0)/AVG_SBUY_RND,2) AS SBUY_RND_PCT,
	ROUND(NULLIF(AVG_FBUY_WON, 0)/AVG_FBUY_RND,2) AS FBUY_RND_PCT
	FROM
		(SELECT TeamID, Name,
		AVG(Eco_Rounds) AS AVG_ECO_RND, 
		AVG(Eco_Rounds_Wons) AS AVG_ECO_WON, 
		AVG(Semi_Eco_Rounds) AS AVG_SECO_RND, 
		AVG(Semi_Eco_Rounds_Wons) AS AVG_SECO_WON, 
		AVG(Semi_Buy_Rounds) AS AVG_SBUY_RND, 
		AVG(Semi_Buy_Rounds_Wons) AS AVG_SBUY_WON, 
		AVG(Full_Buy_Rounds) AS AVG_FBUY_RND, 
		AVG(Full_Buy_Rounds_Wons) AS AVG_FBUY_WON
		FROM cs_go..matcheco me
		JOIN cs_go..team t
			ON me.TeamID = t.ID
		GROUP BY TeamID, Name) SQ)
SELECT C1.*
FROM CTE C1
JOIN CTE C2
	ON C1.TeamID = C2.TeamID AND C1.Name = C2.Name
WHERE C1.SECO_RND_PCT > C2.ECO_RND_PCT
	AND C1.SBUY_RND_PCT > C2.SECO_RND_PCT
	AND C1.FBUY_RND_PCT > C2.SBUY_RND_PCT
ORDER BY 6 DESC, 5 DESC, 4 DESC, 3 DESC
