

--10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields----

CREATE PROC Top_products_division_high_sold_quantity
AS 
BEGIN
WITH Cte_prduct 
AS (
SELECT division
,P.product_code
,P.product
,SUM(sold_quantity) as 'total_sold_quantity'
,ROW_NUMBER() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS [Rank_order]
FROM [dim_product] P
INNER JOIN [fact_sales_monthly] FMS ON FMS.product_code=P.product_code
WHERE FMS.fiscal_year=2021
GROUP BY P.division,P.product,P.product_code)

SELECT * FROM Cte_prduct WHERE  [Rank_order] < 4
END


-----8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity--------


SELECT 
      DATEPART(QQ,date) AS 'Quarter'
     ,SUM(sold_quantity) AS 'Total_Sold_Quantity' 
FROM [fact_sales_monthly]
       WHERE fiscal_year =2020
       GROUP BY DATEPART(QQ,date)
	   ORDER BY DATEPART(QQ,date) DESC


-------Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
--high-performing months and take strategic decisions.
--The final report contains these columns: Month,Year,Gross sales Amount
Create view viw_Gross_sales_amount_customer 
AS (
SELECT 
     DATEPART(month,date) as [Month]
    ,DATENAME(month,SM.date) as [MonthName]
    ,DATEPART(YYYY,Sm.date) as [Year]
    ,SUM(SM.sold_quantity * GP.gross_price) AS [Gross_sales_Amount]
FROM [dbo].[dim_customer] C
INNER JOIN [dbo].[fact_sales_monthly] SM ON SM.customer_code=C.customer_code
INNER JOIN [dbo].[fact_gross_price] GP ON GP.product_code=SM.product_code
    WHERE 
	     customer='Atliq Exclusive'
    Group by DATEPART(month,date)
            ,DATENAME(month,SM.date) 
            ,DATEPART(YYYY,Sm.date))

select Month,MonthName,Year,Gross_sales_Amount from viw_Gross_sales_amount_customer

-----Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.--------------
select distinct market 
from dim_customer nolock
where
	customer = 'Atliq Exclusive'
AND region = 'APAC'

---Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields: segment,product_count-----

select Segment,COunt(product_code) as [Product_Count]
from [dbo].[dim_product]
group by segment

----5.Get the products that have the highest and lowest manufacturing costs.
----The final output should contain these fields: product_code,product,manufacturing_cost

CREATE PROC getmax_min_manufacturing_cost
AS 
BEGIN 
SELECT * FROM (
SELECT TOP 1
       PRO.product_code
      ,PRO.product
      ,MAX(FMC.manufacturing_cost) AS manufacturing_cost
  FROM [dim_product] PRO
INNER JOIN fact_manufacturing_cost FMC ON FMC.product_code=PRO.product_code
    GROUP BY PRO.product_code,PRO.product
    ORDER BY 3 DESC) T1
UNION 
SELECT * FROM (
     SELECT TOP 1
        PRO.product_code
       ,PRO.product
       ,MIN(FMC.manufacturing_cost) AS manufacturing_cost
FROM [dim_product] PRO
INNER JOIN fact_manufacturing_cost FMC ON FMC.product_code=PRO.product_code
      GROUP BY PRO.product_code,PRO.product 
	  ORDER BY MIN(FMC.manufacturing_cost) asc) T2
      ORDER BY 3 DESC
END
--EXEC getmax_min_manufacturing_cost


----6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
----The final output contains these fields: customer_code,customer,average_discount_percentage
create view viw_top5_customer 
as (
SELECT top 5 
       CUST.customer_code
      ,CUST.customer
      ,AVG(pre_invoice_discount_pct) AS 'average_discount_percentage'
FROM [dbo].[dim_customer] CUST
INNER JOIN [dbo].[fact_pre_invoice_deductions] INV ON INV.customer_code=CUST.customer_code
      WHERE INV.fiscal_year=2021 and market='India'
      GROUP BY CUST.customer_code,CUST.customer
      ORDER BY 3 DESC)

	  --select * from viw_top5_customer
  
-----Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-----The final output contains these fields: channel ,gross_sales_mln ,percentage
CREATE PROC channel_gross_sales_2021
AS
SELECT 
     Cus.channel,
     SUM(FGC.gross_price * FSM.sold_quantity) as 'gross_sales_mln'
INTO #T1
FROM dim_customer Cus
INNER JOIN [dbo].[fact_sales_monthly] FSM ON FSM.customer_code=Cus.customer_code
INNER JOIN [dbo].[fact_gross_price] FGC ON FGC.product_code=FSM.product_code
      WHERE FSM.fiscal_year= 2021
      GROUP BY Cus.channel
	  
 DECLARE @total_sales BIGINT
SELECT @total_sales=sum(gross_sales_mln) 
      FROM #T1

select channel
,gross_sales_mln
,((gross_sales_mln *100)/@total_sales) as [Percentage] 
FROM #T1 
   GROUP BY 
         channel
         ,gross_sales_mln
 DROP TABLE #T1

 EXEC channel_gross_sales_2021


 ----What is the percentage of unique product increase in 2021 vs. 2020? 
 ----The final output contains these fields: unique_products_2020,unique_products_2021,percentage_chg CREATE PROC percentage_unique_product_increase  AS BEGIN  DECLARE @unique_products_2020 BIGINT DECLARE @unique_products_2021 BIGINT;with cte_unique_products_2020  as ( select product_code,Count(product_code) as [unique_products_2020] from [fact_sales_monthly] where fiscal_year =2020 group by product_code) select @unique_products_2020=count(product_code) from cte_unique_products_2020 ;with cte_unique_products_2021  as (  select product_code,Count(product_code) as [unique_products_2021] from [fact_sales_monthly] where fiscal_year =2021 group by product_code)  select @unique_products_2021=count(product_code) from cte_unique_products_2021   select @unique_products_2020 as [unique_products_2020],@unique_products_2021  as [unique_products_2021],((@unique_products_2021-@unique_products_2020)*100/@unique_products_2020) as 'percentage_chg'  ENDexec percentage_unique_product_increase-----Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
----The final output contains these fields: segment,product_count_2020,product_count_2021,differenceCREATE PROC segment_increase_unique_productsASBEGINSELECT  Pro.segment,COUNT(DISTINCT FSM.product_code) AS [product_count_2020]INTO #T1FROM [dbo].[dim_product] proINNER JOIN [dbo].[fact_sales_monthly] FSM ON FSM.product_code=Pro.product_codeWHERE FSM.fiscal_year =2020GROUP BY  Pro.segmentSELECT  Pro.segment,COUNT(DISTINCT FSM.product_code) as [product_count_2021]INTO #T2FROM [dbo].[dim_product] proINNER JOIN [dbo].[fact_sales_monthly] FSM ON FSM.product_code=Pro.product_codeWHERE FSM.fiscal_year =2021GROUP BY  Pro.segmentSELECT      T.segment    ,T.product_count_2020    ,T1.product_count_2021    ,(T1.product_count_2021 - T.product_count_2020) as [difference]FROM #T1 TINNER JOIN #T2 T1 ON T.segment=T1.segmentDROP TABLE #T1DROP TABLE #T2END