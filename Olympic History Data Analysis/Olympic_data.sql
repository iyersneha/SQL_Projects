SET sql_mode = '';

SELECT *  FROM DataProjects.OLYMPICS_HISTORY;
SELECT * FROM DataProjects.OLYMPICS_HISTORY_NOC_REGIONS;

-- 1.How many olympic games have been held so far?
SELECT COUNT(DISTINCT games) AS total_olympic_games 
FROM DataProjects.OLYMPICS_HISTORY;

-- 2.List down all the olympic games held so far. 
SELECT year, season, city FROM DataProjects.OLYMPICS_HISTORY
GROUP BY year,season
ORDER BY year;

-- 3.Mention the total number of nations that participated in each olympic games.
SELECT  games , COUNT(DISTINCT region) AS total_countries
FROM DataProjects.OLYMPICS_HISTORY oh
JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
ON oh.noc = ohr.noc
GROUP BY games
ORDER BY games;


-- 4.Which year saw the highest and lowest number of countries participating in Olympics
WITH CTE_countries AS (
	SELECT  games , COUNT(DISTINCT region) AS total_countries
	FROM DataProjects.OLYMPICS_HISTORY oh
	JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr	ON oh.noc = ohr.noc
	GROUP BY games
	ORDER BY games)

SELECT DISTINCT 
	CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries),
		   ' - ',
		   FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS lowest_countries,
	CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries DESC),
			' - ',
            FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS highest_countries
FROM CTE_countries;

-- 5.Which nation has participated in all of the olympic games?
-- total number of games 
SELECT COUNT(DISTINCT games) AS total_olympic_games 
FROM DataProjects.OLYMPICS_HISTORY;

-- games and the country name 
SELECT games,region AS country
FROM DataProjects.OLYMPICS_HISTORY oh
JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr ON oh.noc = ohr.noc
GROUP BY games,region
ORDER BY games;

-- country and their games participated 
WITH CTE_games AS(
	SELECT country, COUNT(1) AS total_games_participated
	FROM (
		SELECT region AS country, games
		FROM DataProjects.OLYMPICS_HISTORY oh
		JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr ON oh.noc = ohr.noc
		GROUP BY games,region)x
	GROUP BY x.country
    ORDER BY total_games_participated DESC
)

SELECT country , total_games_participated
FROM CTE_games 
WHERE total_games_participated = (SELECT COUNT(DISTINCT games) FROM DataProjects.OLYMPICS_HISTORY);


-- 6.Identify the sport which was played in all summer olympics.
-- total number of summer olympics held
SELECT COUNT(DISTINCT games) AS total_summers_played
FROM DataProjects.OLYMPICS_HISTORY
WHERE season = 'Summer';

-- no of summer seasons when a sport has been played 
WITH CTE_summers AS(
	SELECT sport,COUNT(DISTINCT games)AS total_times_played FROM DataProjects.OLYMPICS_HISTORY 
	WHERE season = 'Summer' 
	GROUP BY sport
	ORDER BY total_times_played DESC
)

SELECT sport, total_times_played
FROM CTE_summers 
WHERE total_times_played = (SELECT COUNT(DISTINCT games) FROM DataProjects.OLYMPICS_HISTORY WHERE season = 'Summer')
ORDER BY sport;

-- 7.Which sports were played just once in the Olympics?
SELECT sport,games,COUNT(DISTINCT games)AS total_times_played FROM DataProjects.OLYMPICS_HISTORY 
GROUP BY sport
HAVING total_times_played = 1
ORDER BY sport;

-- 8.Fetch the total number of sports played in each Olympic Game.
SELECT games, COUNT(1) AS no_of_sports_played
FROM(
SELECT DISTINCT games, sport FROM DataProjects.OLYMPICS_HISTORY
ORDER BY games)b
GROUP BY b.games
ORDER BY no_of_sports_played DESC;

-- 9.Fetch oldest athletes to win a gold medal. 
SELECT * FROM (
	SELECT name, sex, age, team, games, city, sport, event, medal,
			RANK()OVER(ORDER BY age DESC) AS age_rank
	FROM DataProjects.OLYMPICS_HISTORY WHERE medal = 'Gold' and age <> 'NA'
	ORDER BY age DESC)x
WHERE x.age_rank = 1;

-- 10. Find the ratio of male and female athletes who participated in all the Olympic games.
WITH CTE_males_females AS(
	SELECT * , ROW_NUMBER()OVER(ORDER BY sex) AS row_no
	FROM(
		SELECT sex,COUNT(1) AS no_of_athletes
		FROM DataProjects.OLYMPICS_HISTORY 
		GROUP BY sex)x)
        
SELECT CONCAT('1 : ',
	ROUND(
		(SELECT no_of_athletes FROM CTE_males_females WHERE row_no=2)/(SELECT no_of_athletes FROM CTE_males_females WHERE row_no=1),2)) 
    AS ratio;

-- 11. Fetch the top 5 athletes who have won the most gold medals
SELECT name, team,total_gold_medals
FROM(
	SELECT *, DENSE_RANK()OVER(ORDER BY x.total_gold_medals DESC) gold_medal_rankings
	FROM(
		SELECT name, team, COUNT(medal) AS total_gold_medals
		FROM DataProjects.OLYMPICS_HISTORY
		WHERE medal = 'Gold'
		GROUP BY name,team ORDER BY total_gold_medals DESC)x
	)s
WHERE s.gold_medal_rankings < 6;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT name, team, total_medals
FROM(
	SELECT *, DENSE_RANK()OVER(ORDER BY x.total_medals DESC) total_medal_rankings
		FROM(
			SELECT name, team, COUNT(medal) AS total_medals
			FROM DataProjects.OLYMPICS_HISTORY
			WHERE medal <> 'NA'
			GROUP BY name,team ORDER BY total_medals DESC)x
		)s
WHERE s.total_medal_rankings < 6;

-- 13. Fetch the top 5 most successful countries in Olympics. Success is defined by the number of medals won. 
SELECT *, DENSE_RANK()OVER(ORDER BY total_medals DESC) AS top_five
FROM(
	SELECT  ohr.region, COUNT(medal) AS total_medals
	FROM DataProjects.OLYMPICS_HISTORY oh
	JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
	ON oh.noc = ohr.noc
	WHERE medal <> 'NA'
	GROUP BY region
	ORDER BY total_medals DESC)x
ORDER BY top_five LIMIT 5;

-- 14. List down total gold, silver and bronze medals won by each country. 
WITH CTE AS(
	SELECT DISTINCT  ohr.region, medal, COUNT(medal) AS total_medals
		FROM DataProjects.OLYMPICS_HISTORY oh
		JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
		ON oh.noc = ohr.noc
		WHERE medal <> 'NA'
		GROUP BY region,medal
		ORDER BY region, medal DESC)
    
SELECT CTE.region AS country, 
		SUM(CASE WHEN medal = 'Gold' THEN total_medals ELSE 0 END) AS 'Gold',
        SUM(CASE WHEN medal = 'Silver' THEN total_medals ELSE 0 END) AS 'Silver',
		SUM(CASE WHEN medal = 'Bronze' THEN total_medals ELSE 0 END) AS 'Bronze'
FROM CTE
GROUP BY region
ORDER BY Gold DESC, Silver DESC, Bronze DESC;

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
WITH CTE AS(
SELECT games,ohr.region, medal, COUNT(medal) AS total_medals
		FROM DataProjects.OLYMPICS_HISTORY oh
		JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
		ON oh.noc = ohr.noc
		WHERE medal <> 'NA'
		GROUP BY games,region,medal
		ORDER BY games, medal)

SELECT games , CTE.region AS country, 
		SUM(CASE WHEN medal = 'Gold' THEN total_medals ELSE 0 END) AS 'Gold',
        SUM(CASE WHEN medal = 'Silver' THEN total_medals ELSE 0 END) AS 'Silver',
		SUM(CASE WHEN medal = 'Bronze' THEN total_medals ELSE 0 END) AS 'Bronze'
FROM CTE
GROUP BY games,region
ORDER BY games;

-- 16. Identify which countries won the most gold, silver and bronze medals in each olympic game. 
WITH CTE AS(
SELECT games ,region AS country, 
		SUM(CASE WHEN medal = 'Gold' THEN total_medals ELSE 0 END) AS 'Gold',
        SUM(CASE WHEN medal = 'Silver' THEN total_medals ELSE 0 END) AS 'Silver',
		SUM(CASE WHEN medal = 'Bronze' THEN total_medals ELSE 0 END) AS 'Bronze'
FROM (
		SELECT games,ohr.region, medal, COUNT(medal) AS total_medals
		FROM DataProjects.OLYMPICS_HISTORY oh
		JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
		ON oh.noc = ohr.noc
		WHERE medal <> 'NA'
		GROUP BY games,region,medal
		ORDER BY games, medal)x
GROUP BY games,region
ORDER BY games)

SELECT DISTINCT games,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY Gold DESC),
		   ' - ',
		   FIRST_VALUE(Gold) OVER(PARTITION BY games ORDER BY Gold DESC)) AS max_gold_won,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY Silver DESC),
			' - ',
            FIRST_VALUE(Silver) OVER(PARTITION BY games ORDER BY Silver DESC)) AS max_silver_won, 
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY Bronze DESC),
			' - ',
			FIRST_VALUE(Bronze) OVER(PARTITION BY games ORDER BY Bronze DESC)) AS max_bronze_won
FROM CTE
ORDER BY games;

-- 17. Identify the country that won the most number of medals in each olympic game. 
WITH CTE AS (
		SELECT games,ohr.region AS country,COUNT(medal) AS total_medals FROM DataProjects.OLYMPICS_HISTORY oh
		JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
		ON oh.noc = ohr.noc
		WHERE medal <> 'NA'
		GROUP BY games,region
		ORDER BY games, medal)

SELECT DISTINCT games, 
		CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY total_medals DESC),
				' - ',
			   FIRST_VALUE(total_medals) OVER(PARTITION BY games ORDER BY total_medals DESC)) AS max_medals_won
FROM CTE;

-- 18. Which countries have never won a gold medal but have won silver or bronze medals?
 WITH CTE AS(
		SELECT region AS country, 
		SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS 'Gold',
        SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS 'Silver',
		SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS 'Bronze'
		FROM DataProjects.OLYMPICS_HISTORY oh
			JOIN DataProjects.OLYMPICS_HISTORY_NOC_REGIONS ohr
			ON oh.noc = ohr.noc
			WHERE medal <> 'NA'
			GROUP BY region
			ORDER BY  region,medal DESC)
            
SELECT * FROM CTE
WHERE Gold = 0 AND (SILVER >0 OR BRONZE > 0);

-- 19. In which sport/event, has India won the highest medals.
SELECT sport, COUNT(medal) AS total_medals FROM DataProjects.OLYMPICS_HISTORY
WHERE team = 'India' and medal <> 'NA'
GROUP BY sport
ORDER BY total_medals DESC LIMIT 1;

-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games.
SELECT team, sport, games, COUNT(medal) AS total_medals FROM DataProjects.OLYMPICS_HISTORY
WHERE team = 'India' AND  medal <> 'NA' AND sport = 'Hockey'
GROUP BY team,sport,games
ORDER BY total_medals DESC;
