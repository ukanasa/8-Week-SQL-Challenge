--Sample Table 
select customer_id, subscriptions.plan_id, plan_name, start_date, price from foodie_fi.subscriptions 
inner join foodie_fi.plans 
on foodie_fi.subscriptions.plan_id = foodie_fi.plans.plan_id 
where customer_id in (1,2,11,13,15,16,18,19); 

--Create temp table 
create temp table s_temp as
select * from foodie_fi.subscriptions; 
create temp table p_temp as 
select * from foodie_fi.plans; 

--B
--How many customers has Foodie-Fi ever had?
select count(distinct customer_id) from s_temp; 

--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select extract(month from start_date) as start_month, count(*) as monthly_trial_users from s_temp 
inner join p_temp 
on s_temp.plan_id = p_temp.plan_id 
where s_temp.plan_id = 0
group by start_month
order by monthly_trial_users desc;  

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select plan_name, count(*) as count_ from s_temp 
inner join p_temp 
on s_temp.plan_id = p_temp.plan_id 
where start_date >= '2021-01-01'
group by plan_name
order by count_ asc; 

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select count(distinct customer_id) as count_churn, 
round((count(distinct customer_id)*1.0/((select count(distinct customer_id) from s_temp)*1.0))*100,1) as churn_percent  
from s_temp 
where plan_id = 4;

--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with subset as 
(select customer_id, plan_id, dense_rank() over(partition by customer_id order by start_date asc) as start_rank from s_temp)
select count(*),
round((count(customer_id)*1.0/((select count(distinct customer_id) from s_temp)*1.0))*100,0) as churn_percent 
from subset 
where start_rank = 2 and plan_id = 4;

--What is the number and percentage of customer plans after their initial free trial?
with subset as 
(select customer_id, plan_id, dense_rank() over(partition by customer_id order by start_date asc) as start_rank from s_temp)
select plan_id, 
count(*),
round((count(customer_id)*1.0/((select count(distinct customer_id) from s_temp)*1.0))*100,1)
from subset 
where start_rank = 2
group by plan_id 

--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with subset as
(select customer_id, 
plan_name, 
start_date,
dense_rank() over(partition by customer_id order by start_date desc) as rank_start_date 
from s_temp 
inner join p_temp 
on s_temp.plan_id = p_temp.plan_id 
where start_date <= '2020-12-31'
order by customer_id asc, start_date asc)
select plan_name, 
count(*) as count_plan,
count(*)*100/(sum(count(*)) over()) as percent_of_count
from subset 
where rank_start_date = 1 
group by plan_name
order by count_plan desc; 

--How many customers have upgraded to an annual plan in 2020?
select distinct count(*)
from s_temp  
where extract(year from start_date) = '2020'
and plan_id = 3;

--How many days on average does it take for a customer to switch to an annual plan from the day they join Foodie-Fi?
with s as 
(select customer_id, min(start_date) as min_start_date, max(start_date) as max_start_date from s_temp
where plan_id in (0,3)
group by customer_id
having count(distinct plan_id) = 2)
select round(avg(max_start_date - min_start_date),2) from s; 

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with subset as 
(select customer_id, 
max(start_date)-min(start_date) as switch_time
from s_temp 
where plan_id in (0,3)
group by customer_id
having count(distinct plan_id) = 2)
select case 
	when switch_time <= 30 then '0-30'
	when switch_time > 30 and switch_time <= 60 then '31-60' 
	when switch_time > 60 and switch_time <= 90 then '61-90'
	when switch_time > 90 and switch_time <= 120 then '91-120'
	when switch_time > 120 and switch_time <= 150 then '121-150'
	else 'above 151'
end as customer_count_bucket,
count(*)
from subset 
group by customer_count_bucket;

--More efficient way
with subset as 
(SELECT
  customer_id,
  (MAX(start_date) - MIN(start_date)) AS switch_time,
  floor((MAX(start_date) - MIN(start_date) - 1) / 30) * 30 || '-' || (floor((MAX(start_date) - MIN(start_date) - 1) / 30) + 1) * 30 AS bucket
FROM s_temp
WHERE plan_id IN (0, 3)
GROUP BY customer_id
HAVING COUNT(DISTINCT plan_id) = 2)
select bucket, count(*) from subset
group by bucket;

--How many customers downgraded from a pro monthly to a basic monthly plan in 2020? 2-->1
with subset as 
(select customer_id, 
start_date, 
plan_id,
lead(plan_id) over(partition by customer_id order by start_date) as lead_rank
from s_temp
where plan_id in (1,2)
and start_date >= '2020-01-01' and start_date < '2021-01-01'
group by customer_id, start_date, plan_id)
select * from subset 
where plan_id = 2 and lead_rank = 2
















