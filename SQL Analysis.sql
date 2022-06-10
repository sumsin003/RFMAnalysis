/* loading data */

create schema mkt;
use mkt;

create table sales_data (
ORDER_NUMBER INT,
QTY_ORDERED INT,
PRICE_EACH int,
ORDER_LINE_NUMBER INT,
SALES int,
ORDER_DATE DATE,
CURRENT_STATUS varchar(150),
QTR_ID INT,
MONTH_ID INT,
YEAR_ID INT,
PRODUCT_LINE varchar(150),
MSRP INT,
PRODUCT_CODE varchar(150),
CUSTOMER_NAME varchar(150),
PHONE varchar(150),
ADDRESS_LINE1 varchar(150),
ADDRESS_LINE2 varchar(150),
CITY varchar(150),
STATE varchar(150),
POSTAL_CODE varchar(150),
COUNTRY varchar(150),
TERRITORY varchar(150),
CONTACT_LASTNAME varchar(150),
CONTACT_FIRSTNAME varchar(150),
DEAL_SIZE varchar(150));

select * from sales_data;
drop table sales_data;

LOAD DATA local INFILE 'F:/Desktop Folders (V IMP)/ANALYST PORTFOLIO/RFM Analysis/SQL/sales_data.csv'
                                            INTO TABLE sales_data
                                            character set latin1
                                            FIELDS TERMINATED BY ',' 
                                            LINES TERMINATED BY '\n'
                                            IGNORE 1 ROWS
(ORDER_NUMBER,
QTY_ORDERED,
PRICE_EACH,
ORDER_LINE_NUMBER,
SALES,
ORDER_DATE,
CURRENT_STATUS,
QTR_ID,
MONTH_ID,
YEAR_ID,
PRODUCT_LINE,
MSRP,
PRODUCT_CODE,
CUSTOMER_NAME,
PHONE,
ADDRESS_LINE1,
ADDRESS_LINE2,
CITY,
STATE,
POSTAL_CODE,
COUNTRY,
TERRITORY,
CONTACT_LASTNAME,
CONTACT_FIRSTNAME,
DEAL_SIZE);

/* Inspecting Data */
select * from sales_data;

/* CHecking unique values */
select distinct current_status from sales_data;
select distinct year_id from sales_data;
select distinct PRODUCT_LINE from sales_data;
select distinct COUNTRY from sales_data;
select distinct DEAL_SIZE from sales_data;
select distinct TERRITORY from sales_data;

select distinct MONTH_ID from sales_data
where year_id = 2003;

/* Grouping sales by productline */
select PRODUCT_LINE, sum(sales) Revenue
from sales_data
group by PRODUCT_LINE
order by 2 desc;


select YEAR_ID, sum(sales) Revenue
from sales_data
group by YEAR_ID
order by 2 desc;

select  DEAL_SIZE,  sum(sales) Revenue
from sales_data
group by  DEAL_SIZE
order by 2 desc;


/* Best month for sales in a specific year? How much was earned that month? */
select  MONTH_ID, sum(sales) as Revenue, count(ORDER_NUMBER) as Frequency
from sales_data
where YEAR_ID = 2004
group by  MONTH_ID
order by 2 desc;


/*--November seems to be the month, what product do they sell in November*/
select PRODUCT_LINE, sum(sales) as Revenue, count(ORDER_NUMBER) as Frequency
from sales_data
where YEAR_ID = 2004 and MONTH_ID = 11
group by  MONTH_ID, PRODUCT_LINE
order by 2 desc;


/*Best customer (this could be best answered with RFM)*/
create table rfm
with rfm as
(
	select 
			CUSTOMER_NAME, 
			sum(sales) as MonetaryValue,
			avg(sales) as AvgMonetaryValue,
			count(ORDER_NUMBER) as Frequency,
			max(ORDER_DATE) as last_order_date,
			(select max(ORDER_DATE) from sales_data) as max_order_date,
			datediff(max(ORDER_DATE),(select max(ORDER_DATE) from sales_data)) as recency
	from sales_data
	group by CUSTOMER_NAME
),
rfm_calc as
(
	select r.*,
			NTILE(4) OVER (order by Recency desc) as rfm_recency,
			NTILE(4) OVER (order by Frequency) as rfm_frequency,
			NTILE(4) OVER (order by MonetaryValue) as rfm_monetary
	from rfm r
)
select c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
concat(cast(rfm_recency as char),cast(rfm_frequency as char),cast(rfm_monetary as char)) as rfm_cell_string
from rfm_calc c;

select * from rfm;


select CUSTOMER_NAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose'
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active'
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from rfm r;

/* What products are most often sold together? 
--select * from sales_data where ORDERNUMBER =  10411

select distinct Order_Number, (
(select GROUP_CONCAT(Product_Code separator ', ')), 1, 1, '') as Product_Codes,
	(select concat(',',PRODUCT_CODE) as Product_Code
	from sales_data p
	where ORDER_NUMBER in 
		(
			select ORDER_NUMBER
			from (
				select ORDER_NUMBER, count(*) as rn
				FROM sales_data
				where current_status = 'Shipped'
				group by ORDER_NUMBER
			) as m
			where rn = 3
		))
        and p.ORDER_NUMBER = s.ORDER_NUMBER
from sales_data s
order by 2 desc;

/*---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from .sales_data
where country = 'UK'
group by city
order by 2 desc



/*---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from .sales_data
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc */