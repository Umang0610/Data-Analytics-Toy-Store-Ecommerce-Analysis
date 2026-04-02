---Advanced Queries utilising window functions,Funnel Analysis,Time Series and other miscellaneous operations
select p.product_name,sum(oi.price_usd)[Price],RANK() OVER(order by sum(oi.price_usd) desc) from [dbo].[cleaned_order_items] oi join [dbo].[cleaned_products] p on oi.product_id=p.product_id group by p.product_name
select user_id,count(*)[Number of Times],avg(count(*)*1.0) over() [Average Times User] from [dbo].[cleaned_website_sessions] group by user_id
---Segment website visitors by their count and then calculate their contribution to website traffic
select user_id,count(*),100.0* count(*)/sum(count(*)) over() [Percentage contribution to traffic] from [dbo].[cleaned_website_sessions] group by user_id;
with cte as(
	select count(*)[Count by user id] from [dbo].[cleaned_website_sessions] group by user_id 
)select cte.[Count by user id],count(*),100.0* count(*)/sum(count(*)) over() [Percentage of users] from cte group by cte.[Count by user id];

with cte_1 as(
	select user_id,count(*) [Count by user id] from [dbo].[cleaned_website_sessions] group by user_id
)select cte_1.[Count by user id],count(*),100.0* sum(cte_1.[Count by user id])/sum(sum(cte_1.[Count by user id])) over() [Percentage of website traffic] from cte_1 group by cte_1.[Count by user id];
--- 🔥 1. Funnel Analysis (VERY IMPORTANT – Missing)
select distinct wp.pageview_url from  [dbo].[cleaned_website_pageviews] wp;
select top 10 * from cleaned_website_pageviews;
with cte as(
	select website_session_id,
	max(case when wp.pageview_url in ('/home','/lander-1','/lander-2','/lander-3','/lander-4','/lander-5') then 1 else 0 end)[Landing Page seen], 
	max(case when wp.pageview_url in ('/products') then 1 else 0 end)[Products Page seen],
	max(case when wp.pageview_url in ('/the-birthday-sugar-panda','/the-forever-love-bear','/the-original-mr-fuzzy','/the-hudson-river-mini-bear')then 1 else 0 end)[Products Details Page seen],
	max(case when wp.pageview_url in ('/cart' ) then 1 else 0 end)[Cart seen],
	max(case when wp.pageview_url in ('/shipping' ) then 1 else 0 end)[Shipping Address Feed],
	max(case when wp.pageview_url in ('/billing','/billing-2' ) then 1 else 0 end)[Billing seen],
	max(case when wp.pageview_url in ('/thank-you-for-your-order' ) then 1 else 0 end)[Thank you page seen]
	from cleaned_website_pageviews wp group by website_session_id
),[count of elements] as(select count(*) [total sessions], sum(cte.[Landing Page seen]) as [Landing Visits],
		sum(cte.[Products Page seen]) as [Products Page Visits],
		sum(cte.[Products Details Page seen]) as [Products Details Page Visits],
		sum(cte.[Cart seen]) as [Cart Visits],
		sum(cte.[Shipping Address Feed]) as [Shipping Address Visits],
		sum(cte.[Billing seen]) as [Billing Visits],
		sum(cte.[Thank you page seen]) as [Thank you page Visits] from cte),

[Percentage of counts] as (select 100.0* sum([Landing Page seen])/sum([Landing Page seen]) [Landing Page %],
100.0* sum([Products Page seen])/sum([Landing Page seen]) [products Page %],
100.0* sum([Products Details Page seen])/sum([Landing Page seen]) [Product details Page %],
100.0* sum([Cart seen])/sum([Landing Page seen])[Cart Page %],

100.0* sum([Shipping Address Feed])/sum([Landing Page seen])[shipping Page %],

100.0* sum([Billing seen])/sum([Landing Page seen])[Billing Page %],
100.0* sum([Thank you page seen])/sum([Landing Page seen])[Thank you Page %] from cte)
select * from [Percentage of counts];

create view funnel_analysis as
with cte as(
	select website_session_id,
	max(case when wp.pageview_url in ('/home','/lander-1','/lander-2','/lander-3','/lander-4','/lander-5') then 1 else 0 end)[Landing Page seen], 
	max(case when wp.pageview_url in ('/products') then 1 else 0 end)[Products Page seen],
	max(case when wp.pageview_url in ('/the-birthday-sugar-panda','/the-forever-love-bear','/the-original-mr-fuzzy','/the-hudson-river-mini-bear')then 1 else 0 end)[Products Details Page seen],
	max(case when wp.pageview_url in ('/cart' ) then 1 else 0 end)[Cart seen],
	max(case when wp.pageview_url in ('/shipping' ) then 1 else 0 end)[Shipping Address Feed],
	max(case when wp.pageview_url in ('/billing','/billing-2' ) then 1 else 0 end)[Billing seen],
	max(case when wp.pageview_url in ('/thank-you-for-your-order' ) then 1 else 0 end)[Thank you page seen]
	from cleaned_website_pageviews wp group by website_session_id
)select 1 AS SortOrder,'Landing Page' as Stage,sum([Landing Page seen]) as Users from cte union all
select 2 ,'Product Page',sum([Products Page seen])from cte union all
select 3 ,'Product Details Page',sum([Products Details Page seen])from cte union all
select 4 ,'Cart Page',sum([Cart seen])from cte union all
select 5 ,'Shipping Page',sum([Shipping Address Feed])from cte union all
select 6 ,'Billing Page',sum([Billing seen])from cte union all
select 7 ,'Thank you Page',sum([Thank you page seen]) from cte go


--select * from [count of elements];

--- Repeat Customer Revenue
with cte_1 as(
	select user_id, count(*)[Count] from [dbo].[cleaned_orders]
	group by user_id
)select case when cte_1.[Count]=1 then 'New'
else 'Repeat' end,count(*),sum(o.price_usd)
from cte_1 join [dbo].[cleaned_orders]o
on cte_1.user_id=o.user_id
group by case when cte_1.[Count]=1 then 'New'
else 'Repeat' end
---Time Series Analysis(Revenue by month,Traffic Trend,Top Performing Days / Hours)
select year,month,sum(price_usd)[Revenue] from [dbo].[cleaned_orders] group by year,month order by [Revenue] desc
select year,month,count(*)[Order] from [dbo].[cleaned_orders] group by year,month order by [Order] desc
select concat(day,' ',month,' ',year)[day],count(*)[Number of orders placed] from [dbo].[cleaned_orders] group by day,month,year order by [Number of orders placed] desc
select concat(day,' ',month,' ',year)[day],hour,count(*)[Number of orders placed] from [dbo].[cleaned_orders] group by hour,day,month,year order by [Number of orders placed] desc
select hour,count(*) from [dbo].[cleaned_orders] group by hour order by hour asc,count(*) desc;

--Traffic Trend
-- Average time spent on a
--Conversion by Campaign + Device (Combination Analysis)
select ws.utm_campaign,ws.device_type,count(distinct o.website_session_id)*100.0 /count(distinct ws.website_session_id) from [dbo].[cleaned_orders]o right join [dbo].[cleaned_website_sessions]ws on o.website_session_id=ws.website_session_id group by ws.utm_campaign,ws.device_type

-- . High-Value Customers (Segmentation)
select user_id,sum(price_usd) from cleaned_orders group by user_id having sum(price_usd)>100;
-- . Product Bundling Insight
select o1.product_id,o2.product_id,count(*) from [dbo].[cleaned_order_items]o1 join [dbo].[cleaned_order_items]o2 on o1.order_id=o2.order_id and o1.product_id<o2.product_id group by o1.product_id,o2.product_id order by count(*) desc;
--- Refund Impact on Profit(Net Profit after refunds)
select sum(o.profit) from dbo.cleaned_orders o
select sum(r.refund_amount_usd) from [dbo].[cleaned_order_refunds]r
select sum(o.profit)-sum(r.refund_amount_usd)[Net profit after refunds] from dbo.cleaned_orders o left join [dbo].[cleaned_order_refunds]r on o.order_id=r.order_id
-- Time Series Analysis with Moving Averages
select cast(created_at as date) as [Date],count(*) as [Daily Orders], avg(1.0* count(*)) over(order by cast(created_at as date) rows between 29 preceding and current row) as [Moving 30day average] from cleaned_orders group by cast(created_at as date)order by [Date];
-- Customer Lifetime Value (CLV) Analysis(cohort analysis)

-- Marketing Channel Attribution(-- First-touch vs Last-touch attribution)
-- For website visits
	--First touch
	select count(distinct website_session_id) from [dbo].[cleaned_website_pageviews]
	select count(distinct website_session_id) from [dbo].[cleaned_website_sessions];
with cte_source as(
	select user_id,utm_source,ROW_NUMBER() over(partition by user_id order by ws.created_at asc)[Rn] from cleaned_website_sessions ws
) select utm_source,count(*)[First Visit Count] from cte_source where Rn=1 group by utm_source order by [First Visit Count] desc;
with cte_end_source as(
	select user_id,utm_source,ROW_NUMBER() over(partition by user_id order by ws.created_at desc)[Rn] from cleaned_website_sessions ws
) select utm_source,count(*)[First Visit Count] from cte_end_source where Rn=1 group by utm_source order by [First Visit Count] desc
-- For conversions of orders after website impression
with cte_source as(
	select o.user_id,utm_source,ROW_NUMBER() over(partition by o.user_id order by ws.created_at)[Rn] from [dbo].[cleaned_orders]o join [dbo].[cleaned_website_sessions]ws on o.website_session_id=ws.website_session_id
)select cte_source.utm_source,count(*) from cte_source where Rn=1 group by utm_source order by count(*) desc;
with cte_source as(
	select o.user_id,utm_source,ROW_NUMBER() over(partition by o.user_id order by ws.created_at desc)[Rn] from [dbo].[cleaned_orders]o join [dbo].[cleaned_website_sessions]ws on o.website_session_id=ws.website_session_id
)select cte_source.utm_source,count(*) from cte_source where Rn=1 group by utm_source order by count(*) desc;

--  RFM Analysis (Recency, Frequency, Monetary)
select user_id,sum(price_usd),count(*) from [dbo].[cleaned_orders] group by user_id order by sum(price_usd) desc;
select max( t.[COUNT]) from (select user_id,count(*)[Count] from [dbo].[cleaned_orders] group by user_id ) as t;
create view rfm_analysis as
with cte_max_date as(
	select cast(max(created_at) as date)[Max Date] from [dbo].[cleaned_orders]
),cte_rfm_calculation as (select user_id,DATEDIFF(day,cast(max(created_at) as date),cte_max_date.[Max Date])[days since last order],count(*)[Frequency of Orders],sum(price_usd)[Revenue]

from cte_max_date cross join [dbo].[cleaned_orders] group by user_id,cte_max_date.[Max Date])
,rfm_metrics as( 
select user_id,[days since last order],[Frequency of Orders],[Revenue],
	case when [days since last order]<=30 then 5
		when [days since last order]<=90 then 4
		when [days since last order]<=300 then 3
		when [days since last order]<=600 then 2
		else 1 end as r_score,
	case when [Frequency of Orders]=3 then 5
		when [Frequency of Orders]=2 then 3
		when [Frequency of Orders]=1 then 1 end as f_score,

	case when[Revenue]>180 then 5
		when[Revenue]>145 then 4
		when[Revenue]>105 then 3
		when[Revenue]>60 then 2
		else 1 end as m_score
	from cte_rfm_calculation
)select user_id,[days since last order],[Frequency of Orders],[Revenue],concat(r_score,f_score,m_score)[RFM Combined],(r_score+f_score+m_score)/3.0[Average Score],
	case when r_score>=4 and f_score>=4 and m_score>=4 then 'Champions'
		when r_score>=4 and f_score>=3 and m_score>=3 then 'Loyal Customer'
		when r_score>= 3 and f_score>=3 and m_score>=3 then 'Potential Loyalist'
		when r_score>=4 and f_score>=2 and m_score>=2 then 'New Customers'
		when r_score>=3 and f_score>=2 and m_score>=2 then 'Promising'
		when r_score <= 2 and f_score >= 4 and m_score >= 4 then 'At Risk - High Value'
		when r_score <= 2 and f_score >= 3 and m_score >= 3 then 'At Risk - Medium Value'
		when r_score <= 2 and f_score >= 2 and m_score >= 2 then 'At Risk - Low Value'
		when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'Hibernating/Lost'
		when r_score >= 3 and f_score = 1 and m_score = 1 then 'Need Activation'
		else 'Others' end as customer_segment
		from rfm_metrics 
	go
select * from rfm_analysis order by [Average Score] desc ;
--- How does conversion rate vary over the years
create index website_session on cleaned_website_sessions(website_session_id)  
create index order_index on cleaned_orders(order_id)  

select cast(ws.created_at as date)[date], 100.0* count(distinct o.website_session_id)/count(distinct ws.website_Session_id)[Conversion Rate] from [dbo].[cleaned_website_sessions]ws left join [dbo].[cleaned_orders]o
on ws.website_session_id =o.website_session_id group by cast(ws.created_at as date) order by [Conversion Rate] desc
select top 1 cast(created_at as date),count(*) from cleaned_orders group by cast(created_at as date) order by count(*) desc;


SELECT 
    COUNT(DISTINCT website_session_id) AS [Total Sessions],
    SUM(MAX(CASE WHEN pageview_url IN (
        '/home','/lander-1','/lander-2',
        '/lander-3','/lander-4','/lander-5'
    ) THEN 1 ELSE 0 END)) AS [Landing Page Sessions]
FROM cleaned_website_pageviews
GROUP BY website_session_id