select * from order_tab;
select * from performance_tab;
select * from user_tab;

-- 1. order pertama tiap cust
select buyerid, shopid, max(order_time), min(order_time) 
from order_tab
group by 1,2
order by 1,2;

--2. Buyer yang order lebih dari 1 kali/bulan
with jumlahorder as (
select extract(month from order_time) as bulan, buyerid, count(orderid) as n_order
from order_tab
group by 1,2
having count(orderid) > 1
order by 1,2)
select buyerid, sum(n_order)
from jumlahorder
group by 1
order by 1;

--3. buyer pertama di tiap toko
with firstorder as (
select distinct
	shopid,
buyerid,
order_time,
min(order_time) over (partition by shopid) as orderpertama 
from order_tab
order by 1)
select * 
from firstorder
where order_time = orderpertama;

--4. TOP 10 gmv dengan country ID dan SG 
WITH sum_gmv as (
SELECT 
	buyerid, SUM(gmv)  as sumgmv
FROM order_tab
JOIN user_tab using(buyerid)
group by 1
order by 1
)
SELECT * 
from sum_gmv 
join (SELECT distinct buyerid, country from user_tab) using(buyerid)
WHERE country in ('ID','SG')
order by 2 desc;

-- 5. jumlah buyer di tiap negara yang itemid-nya ganjil dan genap
SELECT 
	country,
	SUM(CASE WHEN itemid % 2 = 0 THEN 0 ELSE 1 END) as item_ganjil,
	SUM(CASE WHEN itemid % 2 = 0 THEN 1 ELSE 0 END) as item_genap
FROM order_tab
join (SELECT distinct buyerid, country from user_tab) using(buyerid)
group by 1;

--6. Analisa conversion rate(order/view) & click through rate (clicks/impression) dari setiap toko
select * from performance_tab;
select * from order_tab;

with sum_performance as (
select distinct shopid, 
	sum(total_clicks) OVER (partition by shopid) as total_clicks,
	SUM(impressions) OVER (partition by shopid) as total_imp,
	SUM(item_views) OVER (partition by shopid) as total_view, 
	total_order
from performance_tab
join  
	(select shopid, count(orderid) as total_order 
	 from order_tab group by 1) 
	using (shopid) 
	order by 1
)
select shopid, (total_order::float/total_view) * 100 as cvr, 
	(total_clicks::float/total_imp) as ctr
from sum_performance
order by 1;
