create database credit_card_transactions;

use credit_card_transactions;

create table cc_trans
(
transaction_id	int,
city varchar(20),
transaction_date varchar(20),
card_type varchar(20),
exp_type varchar(20),
gender varchar(10),
amount float);

select * from cc_trans;

drop table cc_trans;

ALTER TABLE cc_trans
ADD COLUMN new_transaction_date DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE cc_trans
SET new_transaction_date = STR_TO_DATE(transaction_date, "%d-%m-%Y");

ALTER TABLE cc_trans
DROP COLUMN transaction_date;

ALTER TABLE cc_trans
RENAME COLUMN new_transaction_date TO transaction_date;



-- 1- write a query to print top 5 cities with highest spends and their percentage contribution 
-- of total credit card spends 

with cte as(
select city,sum(amount) as total_spends
from cc_trans
group by city
order by total_spends desc
limit 5),

cte2 as (select sum(amount) as total_amount
from cc_trans)

select *,total_spends/total_amount*100 as percentage_contribution
from cte inner join cte2
on 1=1
order by total_spends desc;

-- 2- write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type, month(transaction_date),year(transaction_date),
sum(amount) as total_spend
from cc_trans
group by card_type,month(transaction_date),year(transaction_date)
order by card_type,total_spend desc)


select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a 
where rn=1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select*,sum(amount) over (partition by card_type order by transaction_date,transaction_id) as total_spend
from cc_trans)

select * from (select *, rank() over (partition by card_type order by total_spend) as rn from cte
where total_spend >= 1000000) a where rn=1;

-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select city,card_type,sum(amount) as amount,
sum(case when card_type='gold' then amount end) as gold_amount
from cc_trans
group by city,card_type
order by city,card_type)

select city,sum(gold_amount)/sum(amount)*100 as percentage_spent
from cte
group by city
having sum(gold_amount) is not null
order by percentage_spent
limit 1;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type 
-- (example format : Delhi , bills, Fuel)

with cte as(
select city,exp_type,sum(amount) as total_amount
from cc_trans
group by city,exp_type)

select city,
min(case when rn_asc=1 then exp_type end) as lowest_expense_type,
max(case when rn_desc=1 then exp_type end) as highest_expense_type
from
(select *,
rank() over (partition by city order by total_amount desc) as rn_desc,
rank() over (partition by city order by total_amount asc) as rn_asc
from cte) A
group by city;

-- 6- write a query to find percentage contribution of spends by females for each expense type

with cte as (
select exp_type,sum(amount) as total_spend
from cc_trans
where gender='F'
group by exp_type),

cte2 as (
select exp_type,sum(amount) as total_spent
from cc_trans
group by exp_type)

select cte.exp_type,total_spend/total_spent*100 as percentage_contribution
from cte inner join cte2 on cte.exp_type=cte2.exp_type
group by cte.exp_type;

-- Alternative method

select exp_type,sum(case when gender='f' then amount else 0 end)/sum(amount)*100 as percentage_contribution
from cc_trans
group by exp_type
order by percentage_contribution desc;

-- 7- Which card and expense type combination saw highest month over month growth in Jan-2014

with cte as
(select card_type,exp_type, year(transaction_date) as yt,month(transaction_date) as mt,sum(amount) as total_spend
from cc_trans
group by card_type,exp_type, year(transaction_date),month(transaction_date)
order by card_type,exp_type, year(transaction_date),month(transaction_date))

select *,(total_spend-prev_month_spent)/prev_month_spent*100 as mom_growth
from (
select *,
lag(total_spend) over(partition by card_type,exp_type order by yt,mt) as prev_month_spent
from cte) A
where prev_month_spent is not null and yt=2014 and mt=1
order by mom_growth desc
limit 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 

select city,sum(amount)/count(1) as ratio
from cc_trans
where DAYOFWEEK(transaction_date) in (1,7)
group by city
order by ratio desc
limit 1;

-- 9- which city took least number of days to reach its 500th transaction after the first 
-- transaction in that city

with cte as (
select *, 
row_number() over (partition by city order by transaction_date, transaction_id) as rn
from cc_trans)

select city,min(transaction_date) as start_date,max(transaction_date) as 500_transaction_date,
TIMESTAMPDIFF(day,min(transaction_date),max(transaction_date)) as no_of_days
from cte
where rn=1 or rn=500
group by city
having count(*)=2
order by no_of_days 
limit 1;
