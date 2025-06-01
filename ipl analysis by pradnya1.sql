use ipl;

  -- Objective Questions --
 -- Q.1) List the different dtypes of columns in table “ball_by_ball” (using information schema)
select column_name, data_type, is_nullable
from information_schema.columns
where table_name = 'ball_by_ball' and column_name in('Match_Id', 'Over_Id', 'Ball_Id', 'Innings_No', 'Team_Batting', 'Team_Bowling', 'Striker_Batting_Position', 
'Striker', 'Non_Striker', 'Bowler', 'Runs_Scored');

-- By reviewing the data types and nullability of the specified columns,
-- one can assess the design of the ball_by_ball table and its suitability for storing detailed cricket match data.

-- Q.2) What is the total number of runs scored in 1st season by RCB (bonus: also include the extra runs using the extra runs table)
select Season_Id, Season_Year 
from Season
order by Season_Id;
    
select sum(b.Runs_Scored) + coalesce(sum(e.Extra_Runs), 0) as Total_Runs
from matches m
join ball_by_ball b on m.Match_Id = b.Match_Id
left join extra_Runs e on m.Match_Id = e.Match_Id and b.Innings_No = e.Innings_No
join team t on (m.Team_1 = t.Team_Id)
where t.Team_Name = 'Royal Challengers Bangalore' and m.Season_Id = 6; 

-- Note:- in this query season_Id- 1,2,3,4,5 gives 0 total runs and if we filter only these session_id 6,7,8,9 we can get the values of total runs, also adding all of these values in query we can get total count of runs i.e in the session id- 6,7,8,9.

--  The query effectively calculates the total runs scored by RCB in the first season, including both regular runs and extra runs. 
-- This comprehensive approach ensures that all contributions to the team's score are accounted for, providing a complete picture of their performance in that season.
 
    
    
    

-- Q.3) How many players were more than the age of 25 during season 2014?
select count(distinct p.Player_Id) as Players_Over_25
from Player p join Season s 
ON s.Season_Year = 2014
where timestampdiff(YEAR, p.DOB, '2014-01-01') > 25;

-- This query counts the number of distinct players over the age of 25 during the 2014 season by calculating their age based on their date of birth (DOB) as of January 1, 2014. 
-- This information can help assess the team's experience level and inform future recruitment strategies.



-- Q.4) How many matches did RCB win in 2013? 
select count(*) as Matches_Won_By_RCB
from matches m join Season s 
on m.Season_Id = s.Season_Id
where s.Season_Year = 2013 and m.Match_Winner = (select Team_Id from Team where Team_Name = 'RCB');
    
    -- This query counts the number of matches won by Royal Challengers Bangalore (RCB) in the 2013 season by checking the match winner against RCB's Team_Id. 
    -- This data provides insights into the team's performance during that season.
    
    
    
    -- Q.5) List the top 10 players according to their strike rate in the last 4 seasons
    -- Step 1: Find the last 4 seasons
with LastFourSeasons as ( select Season_Year from Season 
order by Season_Year desc limit 4),

-- Step 2: Get all Match IDs from the last 4 seasons
MatchesInLastSeasons as (select Match_Id from matches
where Season_Id in (select Season_Id from Season where Season_Year in (select Season_Year from LastFourSeasons))),

-- Step 3: Calculate Total Runs and Balls Faced for each player
PlayerPerformance as (select b.Striker as Player_Id, sum(b.Runs_Scored) as Total_Runs, count(*) AS Balls_Faced,
(sum(b.Runs_Scored) * 1.0 / count(*) * 100) AS Strike_Rate
    from Ball_by_Ball b
    join MatchesInLastSeasons m on b.Match_Id = m.Match_Id
    group by b.Striker),

-- Step 4: Rank players by Strike Rate
RankedPlayers as (select Player_Id, Total_Runs, Balls_Faced, Strike_Rate,
rank() over (order by Strike_Rate desc) as strike_Rank
from PlayerPerformance)

-- Step 5: Select Top 10 Players
select p.Player_Id,p.Strike_Rate, p.Total_Runs, p.Balls_Faced
from RankedPlayers p
where p.strike_Rank <= 10
order by p.Strike_Rate desc;

 -- This query identifies the top 10 players based on their strike rate over the last 4 seasons. It first retrieves the last 4 seasons, 
 -- then gathers match IDs from those seasons, calculates total runs and balls faced for each player, ranks them by strike rate, and finally selects the top 10 players with the highest strike rates.
 
 -- Q.6) What are the average runs scored by each batsman considering all the seasons?
select p.Player_Name, sum(b.Runs_Scored) AS Total_Runs, count(distinct b.Match_Id) AS Total_Innings, avg(b.Runs_Scored) as Average_Runs
from Ball_by_Ball b
join Player p 
on b.Striker = p.Player_Id
group by p.Player_Id
order by Average_Runs desc;
    
-- This query calculates the average runs scored by each batsman across all seasons. It sums the total runs, 
-- counts distinct innings for each player, and computes the average runs per innings, providing a comprehensive view of each batsman's performance.
    
    
    
   -- Q.7) What are the average wickets taken by each bowler considering all the seasons?
   -- Step 1: Identify total wickets taken by each bowler
with BowlerWickets as (select b.Bowler as Bowler_Id, count(w.Player_Out) as Total_Wickets
	from Wicket_Taken w
	join ball_by_ball b on w.Match_Id = b.Match_Id
     and w.Over_Id = b.Over_Id and w.Ball_Id = b.Ball_Id and w.Innings_No = b.Innings_No
    group by b.Bowler),

-- Step 2: Count the total number of seasons
TotalSeasons as (select count(distinct Season_Year) as Season_Count from Season)

-- Step 3: Calculate average wickets per season for each bowler
select bw.Bowler_Id, bw.Total_Wickets,
round(bw.Total_Wickets * 1.0 / ts.Season_Count, 2) as Average_Wickets_Per_Season
from BowlerWickets bw
cross join TotalSeasons ts
order by Average_Wickets_Per_Season desc;

-- This query calculates the average wickets taken by each bowler across all seasons. It first identifies the total wickets for each bowler, 
-- counts the total number of seasons,and then computes the average wickets per season, providing insights into each bowler's performance over time.
  
  
  -- Q.8) List all the players who have average runs scored greater than the overall average and who have taken wickets greater than the overall average
with PlayerWickets AS (select pm.Player_Id, p.Player_Name, count(wt.Player_Out) as total_wickets
    from Player_Match pm
    join Player p on pm.Player_Id = p.Player_Id
    left join Wicket_Taken wt on pm.Match_Id = wt.Match_Id and pm.Player_Id = wt.Player_Out
    group by pm.Player_Id, p.Player_Name),
OverallWicketAverage as (select avg(total_wickets) as avg_wickets
from PlayerWickets)
select pw.Player_Id, pw.Player_Name, pw.total_wickets
from PlayerWickets pw
where pw.total_wickets > (select avg_wickets from OverallWicketAverage);

-- This query lists players who have both an average runs scored greater than the overall average and total wickets taken greater than the overall average. 
-- It first calculates total wickets for each player, then determines the overall average wickets, and finally filters players based on these criteria.


  -- Q.9)Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.
create table rcb_record (
    Venue_Id int not null,
    Venue_Name varchar(450) not null,
    Wins int default 0,
    Losses int default 0,
  primary key (Venue_Id));
insert into rcb_record (Venue_Id, Venue_Name, Wins, Losses)
select v.Venue_Id, v.Venue_Name,
    count(case when m.Match_Winner = 1 then 1 else null end) As Wins,  
    count(case when m.Match_Winner != 1 then 1 else null end) As Losses
from matches m
join Venue v ON m.Venue_Id = v.Venue_Id
where (m.Team_1 = 1 or m.Team_2 = 1)  
group by v.Venue_Id, v.Venue_Name;

-- This script creates a table named rcb_record to track the wins and losses of Royal Challengers Bangalore (RCB) at individual venues. 
-- It inserts data by counting wins and losses based on match results where RCB is either Team 1 or Team 2.

-- Q.10) What is the impact of bowling style on wickets taken?
select bs.Bowling_skill as Bowling_Style,
    count(wt.Player_Out) as Total_Wickets
from Wicket_Taken wt
join Ball_by_Ball bb 
  on  wt.Match_Id = bb.Match_Id and wt.Over_Id = bb.Over_Id 
   and wt.Ball_Id = bb.Ball_Id and wt.Innings_No = bb.Innings_No
join Bowling_Style bs on bb.Bowler = bs.Bowling_Id
group by bs.Bowling_skill
order by Total_Wickets desc;

-- This query analyzes the impact of bowling style on the number of wickets taken. It counts total wickets for each 
-- bowling style by joining the Wicket_Taken, Ball_by_Ball, and Bowling_Style tables, providing insights into which styles are most effective.


-- Q.11)Write the SQL query to provide a status of whether the performance of the team is better than the previous year's performance on the basis of the number of runs scored by the team in the season and the number of wickets taken 
-- Step 1: Calculate total runs scored by each team in each season
with TeamRuns as (select m.Season_Id, m.Team_1 as Team_Id, sum(b.Runs_Scored) as Total_Runs
    from Matches m
    join Ball_by_Ball b on m.Match_Id = b.Match_Id and b.Team_Batting = m.Team_1
    group by m.Season_Id, m.Team_1
    union all
    select m.Season_Id, m.Team_2 as Team_Id, sum(b.Runs_Scored) as Total_Runs
    from Matches m
    join Ball_by_Ball b on m.Match_Id = b.Match_Id and b.Team_Batting = m.Team_2
    group by m.Season_Id, m.Team_2),

-- Step 2: Calculate total wickets taken by each team in each season
TeamWickets as (select m.Season_Id, b.Team_Bowling as Team_Id, count(w.Player_Out) as Total_Wickets
from Matches m
join Ball_by_Ball b on m.Match_Id = b.Match_Id
  join Wicket_Taken w on w.Match_Id = b.Match_Id and w.Over_Id = b.Over_Id and w.Ball_Id = b.Ball_Id and w.Innings_No = b.Innings_No
   group by m.Season_Id, b.Team_Bowling),

-- Step 3: Combine runs and wickets for each team in each season
SeasonPerformance as (select tr.Season_Id, tr.Team_Id, tr.Total_Runs, coalesce(tw.Total_Wickets, 0) as Total_Wickets
    from TeamRuns tr
   left join TeamWickets tw on tr.Season_Id = tw.Season_Id and tr.Team_Id = tw.Team_Id),

-- Step 4: Compare performance with the previous season
PerformanceComparison as (select sp.Team_Id, t.Team_Name,sp.Season_Id, s.Season_Year, sp.Total_Runs, sp.Total_Wickets,
        lag(sp.Total_Runs) over (partition by sp.Team_Id order by sp.Season_Id) as Prev_Season_Runs,
        lag(sp.Total_Wickets) over(partition by sp.Team_Id order by sp.Season_Id) as Prev_Season_Wickets,
        case  when sp.Total_Runs > lag(sp.Total_Runs) over (partition by sp.Team_Id order by sp.Season_Id)
             and sp.Total_Wickets > lag(sp.Total_Wickets) over(partition by sp.Team_Id order by sp.Season_Id)
            then 'Better'
            else 'Worse'
        end as Performance_Status
    from SeasonPerformance sp
    join Team t on sp.Team_Id = t.Team_Id
    join Season s on sp.Season_Id = s.Season_Id
)

-- Final Output: Team performance comparison
select Team_Name, Season_Year, Total_Runs, Total_Wickets, Prev_Season_Runs, Prev_Season_Wickets, Performance_Status
from PerformanceComparison
where Prev_Season_Runs is not null 
order by Team_Name, Season_Year;


-- This query evaluates the performance of each team by comparing total runs scored and wickets taken in the current season against the previous season. 
-- It calculates total runs and wickets, combines the data, and determines if the performance is 'Better' or 'Worse' than the previous year.



-- Q.12) Can you derive more KPIs for the team strategy?
--  Batting Performance KPIs:
select Team_Batting, avg(Runs_Scored) as Avg_Runs_Per_Over
from ball_by_ball
group by Team_Batting;

-- Run Rate in Powerplays vs. Middle and Death Overs:
select Team_Batting,
    avg(case when Over_Id <= 6 then Runs_Scored else 0 end) as Powerplay_Run_Rate,
    avg(case when Over_Id BETWEEN 7 and 15 then Runs_Scored else 0 end ) as Middle_Over_Run_Rate,
   avg(case when Over_Id > 15 then Runs_Scored else 0 end) as Death_Over_Run_Rate
from ball_by_ball
group by Team_Batting;

-- Boundary Percentage
select Team_Batting,
    (sum(case when Runs_Scored = 4 then 1 when Runs_Scored = 6 then 1 else 0 end) * 100) / count(*) as Boundary_Percentage
from ball_by_ball
group by Team_Batting;

-- Bowling Strategy KPIs:
-- Bowling Phase Strategy (Economy Rates in Different Phases):
select Team_Bowling,
    avg(case when Over_Id <= 6 then Runs_Scored else 0 end) as Powerplay_Economy_Rate,
   avg(case when Over_Id between 7 and 15 then Runs_Scored else 0 end) as Middle_Over_Economy_Rate,
    avg(case when Over_Id > 15 then Runs_Scored else 0 end) as Death_Over_Economy_Rate
from Ball_by_Ball
group by Team_Bowling;

-- Fielding Efficiency (Catches and Run Outs):
select Team_Batting, sum(case when Runs_Scored is null then 1 else 0 end) as Fielding_Efficiency
from ball_by_ball
group by Team_Batting;

-- Match strategy KPI's:
select Toss_Decide, count(*) as Number_of_Matches,
    sum(case when Match_Winner = Toss_Winner then 1 else 0 end) as  Matches_Won_After_Toss_Decision
from matches
group by Toss_Decide;

-- Batting Hand Strategy:
select Batting_hand, sum(Runs_Scored) as Total_Runs,
    count(distinct Player_Id) as Number_of_Batsmen
from Player
join Ball_by_Ball on Player.Player_Id = Ball_by_Ball.Striker
group by Batting_hand;
    
-- Extra Runs Strategy:
select sum(Extra_Runs) as Total_Extra_Runs
from Extra_Runs
where Match_Id in (select Match_Id from Matches where Team_1 = 1 or Team_2 = 1);  
    
    -- Win Margin Strategy:
 select Win_Type, avg(Win_Margin) as Avg_Win_Margin
from matches
group by Win_Type;
    
    -- Man of the Match Strategy:
 select Player_Name, count(*) as Number_of_Times_Man_of_the_Match
from matches
join Player on Matches.Man_of_the_Match = Player.Player_Id
group by Player_Name;
    
    -- This set of queries derives various Key Performance Indicators (KPIs) for team strategy, focusing on batting performance, bowling strategy, fielding efficiency, match strategy, and individual player contributions. 
    -- These KPIs provide insights into team strengths and areas for improvement.
    

-- Q.13) Using SQL, write a query to find out the average wickets taken by each bowler in each venue. Also, rank the gender according to the average value.
select p.Player_Name, v.Venue_Name, avg(w.Total_Wickets) as Average_Wickets,
rank() over (partition by v.Venue_Name order by avg(w.Total_Wickets) desc) as `Rank`
from (select Match_Id, Player_Out, count(*) as Total_Wickets from Wicket_Taken
group by Match_Id, Player_Out) w
join Player p on w.Player_Out = p.Player_Id
join Matches m on w.Match_Id = m.Match_Id
join Venue v on m.Venue_Id = v.Venue_Id
group by p.Player_Name, v.Venue_Name
order by v.Venue_Name, Average_Wickets desc;

-- This query calculates the average wickets taken by each bowler at each venue. 
-- It ranks bowlers based on their average wickets per venue, providing insights into bowler performance in different locations.




-- Q.14)Which of the given players have consistently performed well in past seasons? (will you use any visualization to solve the problem)
with PlayerPerformance as (
    select p.Player_Id, p.Player_Name, sum(case when pm.Role_Id = 1 then b.Runs_Scored else 0 end) as Total_Runs,
	sum(case when pm.Role_Id = 2 then w.Player_Out else 0 end) as Total_Wickets,
	count(distinct m.Season_Id) as Seasons_Played
    from Player p
    left join Player_Match pm on p.Player_Id = pm.Player_Id
    left join Ball_by_Ball b on pm.Match_Id = b.Match_Id and b.Striker = p.Player_Id
    left join Wicket_Taken w on pm.Match_Id = w.Match_Id and w.Player_Out = p.Player_Id
    left join Matches m on pm.Match_Id = m.Match_Id
    group by p.Player_Id, p.Player_Name)
select Player_Id, Player_Name, Total_Runs, Total_Wickets, Seasons_Played
from PlayerPerformance
where (Total_Runs > 500 and Seasons_Played > 3) or (Total_Wickets > 20 and Seasons_Played > 3)
order by Total_Runs desc, Total_Wickets desc;

-- Components Used in the Query:
-- 1. Common Table Expression (CTE): Creates a temporary result set (PlayerPerformance) for aggregation.
-- 2. SELECT Statement: Specifies the columns to retrieve (Player_Id, Player_Name, Total_Runs, Total_Wickets, Seasons_Played).
-- 3. Aggregate Functions: SUM() calculates total runs and wickets; COUNT(DISTINCT ...) counts distinct seasons.
-- 4. CASE Statement: Differentiates between runs scored by batsmen and wickets taken by bowlers.
-- 5. JOINs: LEFT JOIN combines data from multiple tables to gather comprehensive performance data.
-- 6. GROUP BY Clause: Groups results by player ID and name for aggregation.
-- 7. WHERE Clause: Filters results to include only players meeting performance criteria.
-- 8. ORDER BY Clause: Sorts final results by total runs and wickets in descending order.

-- Identify Consistent Performers (Using Man of the Match):
select P.Player_Name, count(M.Match_Id) as Matches_Won
from matches M
join Player P on M.Man_of_the_Match = P.Player_Id
group by P.Player_Name
having count(M.Match_Id) > 5 
order by Matches_Won desc;

-- This query identifies players who have been awarded 'Man of the Match' in more than five matches. 
-- It counts the number of matches each player has won this award, filtering for those with more than five wins.

    

-- Q.15) Are there players whose performance is more suited to specific venues or conditions? (how would you present this using charts?) 
select P.Player_Name, V.Venue_Name, count(M.Match_Id) as Matches_Performed, count(M.Man_of_the_Match) as Man_of_the_Match_Count
from matches M
join Player P on M.Man_of_the_Match = P.Player_Id
join Venue V on M.Venue_Id = V.Venue_Id
group by P.Player_Name, V.Venue_Name
having count(M.Man_of_the_Match) > 0  
order by P.Player_Name, V.Venue_Name;

-- This query identifies players whose performances are notable at specific venues by counting the number of matches played and the number of 'Man of the Match' awards received at each venue. 
-- It filters for players who have received at least one 'Man of the Match' award.



-- Subjective Questions
-- Q.1) How does the toss decision affect the result of the match? (which visualizations could be used to present your answer better) And is the impact limited to only specific venues?
select T.Toss_Name, M.Win_Type, count(M.Match_Id) as Matches_Played,
    count(case when M.Match_Winner = M.Toss_Winner then 1 end ) as Wins_For_Toss_Winner,
    count(case when M.Match_Winner != M.Toss_Winner then 1 end ) as Wins_For_Opponent
from matches M
join Toss_Decision T on M.Toss_Decide = T.Toss_Id
group by T.Toss_Name, M.Win_Type
order by Matches_Played desc;

-- This query analyzes the impact of toss decisions on match outcomes by counting matches played, wins for the toss winner, and wins for the opponent. 
-- It groups the results by toss decision and match win type to assess how often the toss winner also wins the match.


-- Q.2) 	Suggest some of the players who would be best fit for the team.
with PlayerPerformance as (select p.Player_Id, p.Player_Name, sum(coalesce(b.Runs_Scored, 0)) as Total_Runs,
count(wt.Player_Out) as Total_Wickets, count(b.Match_Id) as Matches_Played,
avg(coalesce(b.Runs_Scored, 0)) as Average_Runs, avg(case when wt.Player_Out is not null then 1 else 0 end) as Wicket_Taking_Average
    from Player p
    left join Ball_by_Ball b on p.Player_Id = b.Striker  
  left join Wicket_Taken wt on b.Match_Id = wt.Match_Id 
  and b.Over_Id = wt.Over_Id and b.Ball_Id = wt.Ball_Id and b.Innings_No = wt.Innings_No
    group by p.Player_Id, p.Player_Name)
    select pp.Player_Id, pp.Player_Name, pp.Total_Runs, pp.Total_Wickets, pp.Average_Runs, pp.Wicket_Taking_Average
    from PlayerPerformance pp
     where pp.Average_Runs > 30  or pp.Total_Wickets > 10  
     order by pp.Average_Runs desc, pp.Total_Wickets desc;
    
   -- This query identifies potential players for the team based on their performance metrics, including total runs, total wickets, average runs, and wicket-taking average. 
-- It filters for players with an average of more than 30 runs or more than 10 total wickets, indicating strong performance.
    
    
    
    
    

-- Q.3)	What are some of the parameters that should be focused on while selecting the players?
select P.Player_Id, P.Player_Name, avg(BB.Runs_Scored) as Batting_Average,
avg(BB.Runs_Scored * 1.0 / (case when W.Player_Out > 0 then W.Player_Out else 1 end)) as Batting_Strike_Rate,
    avg(case when BB.Runs_Scored > 0 then 1 else 0 end) as Consistency_Score,  
    avg(case when W.Player_Out is not null then 1 else 0 end) as Wickets_Performance,  
    count(distinct M.Season_Id) as Number_of_Seasons,
   sum(case when BB.Runs_Scored > 50 then 1 else 0 end) as Matches_With_50_Plus,  
   sum(case when W.Player_Out is not null then 1 else 0 end) as Matches_With_Wickets,  
    avg(BB.Runs_Scored) +avg(case when W.Player_Out is not null then 10 else 0 end) as Total_Performance_Score  
from Player P
join Ball_by_Ball BB on P.Player_Id = BB.Striker or P.Player_Id = BB.Bowler
left join Wicket_Taken W on BB.Match_Id = W.Match_Id and BB.Over_Id = W.Over_Id and BB.Ball_Id = W.Ball_Id
join matches M on BB.Match_Id = M.Match_Id
group by P.Player_Id, P.Player_Name
having count(distinct M.Season_Id) > 1  
order by Total_Performance_Score desc;  

-- This query evaluates player performance based on several key parameters: batting average, strike rate, consistency score, wicket performance, number of seasons played, matches with 50+ runs, matches with wickets, and a total performance score. 
-- It filters for players who have participated in more than one season, providing a comprehensive view of their capabilities.


-- Q.4)Which players offer versatility in their skills and can contribute effectively with both bat and ball? 
select P.Player_Id, P.Player_Name, B.Batting_hand as Batting_Style, BS.Bowling_skill as Bowling_Style, C.Country_Name
from Player P
join Batting_Style B on P.Batting_hand = B.Batting_Id
join Bowling_Style BS on P.Bowling_skill = BS.Bowling_Id
join Country C on P.Country_Name = C.Country_Id
where P.Bowling_skill is not null;


-- This query identifies players who possess versatility by contributing effectively with both bat and ball. 
-- It retrieves player names along with their batting style and bowling skill, filtering for players with a defined bowling skill.

-- Q.5)Are there players whose presence positively influences the morale and performance of the team? 
-- Identify Players with the Most "Man of the Match" Awards
select p.Player_Id, p.Player_Name, count(m.Man_of_the_Match) as Man_of_the_Match_Awards
from Player p
join Matches m on p.Player_Id = m.Man_of_the_Match
group by p.Player_Id, p.Player_Name
order by Man_of_the_Match_Awards desc;
    
    -- This query identifies players who have received the most 'Man of the Match' awards, indicating their impact on individual match outcomes.
    
-- Analyze Win Rates of Players
    select p.Player_Id, p.Player_Name, count(pm.Match_Id) as Matches_Played,
    sum(case when m.Match_Winner = pm.Team_Id then 1 else 0 end) as Wins,
    (sum(case when m.Match_Winner = pm.Team_Id then 1 else 0 end) * 100.0 / count(pm.Match_Id)) as Win_Percentage
from Player p
join Player_Match pm on p.Player_Id = pm.Player_Id
join Matches m on pm.Match_Id = m.Match_Id
group by p.Player_Id, p.Player_Name
having count(pm.Match_Id) > 0  
order by Win_Percentage desc;


-- This query analyzes the win rates of players by counting matches played and wins, calculating the win percentage for each player.

-- Identify Key Players by Role    
select p.Player_Id, p.Player_Name, pm.Role_Id, count(pm.Match_Id) as Matches_Played
from Player p
join Player_Match pm on p.Player_Id = pm.Player_Id
join Matches m on pm.Match_Id = m.Match_Id
where pm.Role_Id in (1, 2)  
group by p.Player_Id, p.Player_Name, pm.Role_Id
order by Matches_Played desc;

-- This query identifies key players based on their roles (e.g., Captain, All-Rounder) and counts the matches they have played.


-- Q.6)What would you suggest to RCB before going to the mega auction? 
--  Analyze Venue Performance
select Venue_Name, Wins, Losses, (Wins * 100.0 / (Wins + Losses)) as Win_Percentage
from rcb_record
order by Win_Percentage desc;

-- Identify Key Player Roles
select Role_Desc, count(Player_Id) as Number_of_Players
from Player_Match pm
join Rolee r on pm.Role_Id = r.Role_Id
group by Role_Desc;
    
-- Analyze Performance Metrics
select p.Player_Name, avg(b.Runs_Scored) as Average_Runs, count(w.Player_Out) as Total_Wickets
from Player p
left join Ball_by_Ball b on p.Player_Id = b.Striker
left join Wicket_Taken w on b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id and b.Ball_Id = w.Ball_Id
group by p.Player_Id
order by Average_Runs desc;
    
-- // By focusing on these strategic areas, RCB can enhance their chances of building a competitive squad during the mega auction. The goal should be to create a balanced team that can perform consistently and has the potential to win the IPL title.



-- Q.7)What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies
-- Identify High-Scoring Matches
select m.Match_Id, t1.Team_Name as Team_1, t2.Team_Name as Team_2, m.Match_Date, m.Win_Margin, m.Match_Winner
from Matches m
join Team t1 on m.Team_1 = t1.Team_Id
join Team t2 on m.Team_2 = t2.Team_Id
where m.Win_Margin is not null
order by m.Win_Margin desc
limit 10;  


 -- Analyze Player Contributions in High-Scoring Matches
select p.Player_Id, p.Player_Name, count(pm.Match_Id) as Matches_Played,
sum(case when m.Match_Winner = pm.Team_Id then 1 else 0 end) as Wins, avg(b.Runs_Scored) as Average_Runs
from Player p
join Player_Match pm on p.Player_Id = pm.Player_Id
join Matches m on pm.Match_Id = m.Match_Id
join Ball_by_Ball b on pm.Match_Id = b.Match_Id and pm.Player_Id = b.Striker
where m.Win_Margin is not null  -- Only consider matches with a win margin
group by p.Player_Id, p.Player_Name
order by Average_Runs desc
limit 10;

-- Identify Teams with High Win Margins
select t.Team_Name, count(m.Match_Id) as Matches_Played, avg(m.Win_Margin) as Average_Win_Margin
from Matches m
join Team t on m.Match_Winner = t.Team_Id
group by t.Team_Name
order by Average_Win_Margin desc;

-- Analyze high-scoring matches, player contributions, team performances, and the impact of individual awards. 
-- By running these queries, we can gather insights that can inform team strategies and enhance understanding of factors contributing to high-scoring games.



-- Q.8)Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB. 
-- Analyze Home-Ground Performance
select m.Venue_Id, v.Venue_Name, count(m.Match_Id) as Total_Matches,
   sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) as Wins,
   sum(case when m.Match_Winner != r.Team_Id then 1 else 0 end) as Losses,
    (sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) * 100.0 / COUNT(m.Match_Id)) as Win_Percentage
from Matches m
join Venue v on m.Venue_Id = v.Venue_Id
join Team r on m.Team_1 = r.Team_Id or m.Team_2 = r.Team_Id
where r.Team_Name = 'Royal Challengers Bangalore'  
group by m.Venue_Id, v.Venue_Name
order by Win_Percentage desc;

-- Monitor and Evaluate Performance
select s.Season_Year, count(m.Match_Id) as Total_Home_Matches,
   sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) as Wins,
  (sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) * 100.0 / count(m.Match_Id)) as Win_Percentage
from Matches m
join Team r on (m.Team_1 = r.Team_Id or m.Team_2 = r.Team_Id)
join Season s on m.Season_Id = s.Season_Id
where r.Team_Name = 'Royal Challengers Bangalore'  
and m.Venue_Id = (select Venue_Id from Venue where Venue_Name = 'M Chinnaswamy Stadium') 
group by s.Season_Year
order by s.Season_Year;

-- By analyzing home-ground performance and implementing targeted strategies, RCB can maximize their home advantage. 
-- This includes player selection, preparation, fan engagement, tactical adjustments, and ongoing performance monitoring. 
-- These strategies can help RCB improve their chances of winning at home and enhance overall team performance. 


-- Q.9)Come up with a visual and analytical analysis of the RCB's past season's performance and potential reasons for them not winning a trophy.
 -- Analyze Overall Performance:
select count(m.Match_Id) as Total_Matches, sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) as Wins,
sum(case when m.Match_Winner != r.Team_Id then 1 else 0 end) as Losses,
(sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) * 100.0 / count(m.Match_Id)) as Win_Percentage
from Matches m
join Team r on (m.Team_1 = r.Team_Id or m.Team_2 = r.Team_Id)
where r.Team_Name = 'Royal Challengers Bangalore' and m.Season_Id = (select max(Season_Id) from Season);  
    
-- Analyze Performance by Venue:
select v.Venue_Name, count(m.Match_Id) AS Total_Matches, sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) as Wins,
sum(case when m.Match_Winner != r.Team_Id then 1 else 0 end) as Losses,
(sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) * 100.0 / count(m.Match_Id)) as Win_Percentage
from Matches m
join Venue v on m.Venue_Id = v.Venue_Id
join Team r on (m.Team_1 = r.Team_Id or m.Team_2 = r.Team_Id)
where r.Team_Name = 'Royal Challengers Bangalore' and m.Season_Id = (select max(Season_Id) from Season) 
group by v.Venue_Name
order by Win_Percentage desc;
    
-- Analyze Key Player Contributions:
select p.Player_Name, count(pm.Match_Id) as Matches_Played, sum(case when m.Match_Winner = r.Team_Id then 1 else 0 end) as Wins,
avg(b.Runs_Scored) as Average_Runs, count(distinct m.Man_of_the_Match) as Man_of_the_Match_Awards
from Player p
join Player_Match pm ON p.Player_Id = pm.Player_Id
join Matches m on pm.Match_Id = m.Match_Id
join Ball_by_Ball b on pm.Match_Id = b.Match_Id and pm.Player_Id = b.Striker
join Team r on (m.Team_1 = r.Team_Id or m.Team_2 = r.Team_Id)
where r.Team_Name = 'Royal Challengers Bangalore' and m.Season_Id = (select max(Season_Id) from Season)  
group by p.Player_Id, p.Player_Name
order by Average_Runs desc;


-- //Overall Performance: RCB's low win percentage reflects inconsistency in converting matches into victories, impacting their trophy chances.
-- Performance by Venue: Strong home performance paired with struggles away indicates difficulties in adapting to different conditions,highlighting the need for improvement.
-- Key Player Contributions: Reliance on a few standout players without sufficient support from the team may have hindered overall success.


-- Q.10	How would you approach this problem, if the objective and subjective questions weren't given?
select r.Role_Desc, p.Player_Name as Captain_Name, pm.Team_Id,
    count(case when wb.Win_Type in ('Runs', 'Wickets') then 1 end) as Total_Wins,
	count(case when wb.Win_Type = 'Tie' then 1 end) as Total_Ties,
	count(case when wb.Win_Type = 'No Result' then 1 end) as Total_No_Results
from Rolee r
join Player_Match pm on r.Role_Id = pm.Role_Id
join Player p on p.Player_Id = pm.Player_Id
join Matches m on m.Match_Id = pm.Match_Id
join Win_By wb on wb.Win_Id = m.Win_Type
where r.Role_Desc in ('Captain', 'CaptainKeeper')
group by r.Role_Desc, p.Player_Name, pm.Team_Id
order by Total_Wins desc, Total_Ties asc, Total_No_Results asc;

-- This query analyzes the performance of players in captain and wicketkeeper roles by counting their total wins, ties, and no results. 
-- It groups the results by role description and player name, providing insights into the effectiveness of captains and wicketkeepers in leading their teams.


-- Q.11)In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" instead of "Delhi_Daredevils". Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".
select * from Team where Team_Id = 6;

update Team set Team_Name = "Delhi Daredevils" where Team_Id = 6;

select count(Man_of_the_Match) from Matches;

-- Note- already have team name as “Delhi-Daredevils” in a team column.
-- This query updates the "Opponent_Team" column in the "Match" table, replacing all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".
-- also already have a team name "Delhi-Daredevils" in Team table.


