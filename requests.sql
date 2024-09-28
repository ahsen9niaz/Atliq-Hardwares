# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT
	DISTINCT market 
FROM
	dim_customer
WHERE
region = 'APAC' AND customer = 'Atliq Exclusive';



# 2. What is the percentage of unique product increase in 2021 vs. 2020?
SELECT 
	COUNT(DISTINCT( CASE WHEN cost_year = 2020 THEN product_code END)) as unique_products_2020,
	COUNT(DISTINCT( CASE WHEN cost_year = 2021 THEN product_code END)) as unique_products_2021,
	((COUNT(DISTINCT CASE WHEN cost_year = 2021 THEN product_code END) - 
	COUNT(DISTINCT CASE WHEN cost_year = 2020 THEN product_code END)) / 
	COUNT(DISTINCT CASE WHEN cost_year = 2020 THEN product_code END)) * 100 AS percentage_chg
FROM 
    fact_manufacturing_cost;


# 3. Provide a report with all the unique product counts for each segment and sort thrm in descending order of product counts
SELECT 
	segment , COUNT(DISTINCT(product_code)) as product_count 
FROM 
	dim_product
GROUP BY
	segment
ORDER BY
	product_count DESC;
	 
# 4. Which segment had the most increase in unique products in 2021 vs 2020?
 WITH change_segment AS ( 
    SELECT 
        fact_sales_monthly.product_code, 
        fact_sales_monthly.fiscal_year, 
        fact_sales_monthly.sold_quantity, 
        dim_product.product, 
        dim_product.segment
    FROM 
        dim_product 
    LEFT JOIN 
        fact_sales_monthly 
    ON 
        fact_sales_monthly.product_code = dim_product.product_code
)
SELECT
    segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS difference
FROM 
    change_segment
WHERE 
    sold_quantity IS NOT NULL
GROUP BY
    segment;   
    
    
# 5. Get the products that have the highest and lowest manufacturing costs
WITH cost AS(
    SELECT 
		fact_manufacturing_cost.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost 
	FROM 
        fact_manufacturing_cost
	LEFT JOIN
		dim_product
	ON
		dim_product.product_code = fact_manufacturing_cost.product_code)
	(SELECT *
	FROM 
		cost
	ORDER BY 
    manufacturing_cost DESC LIMIT 1)
UNION 
	(SELECT *
	FROM 
		cost
	ORDER BY 
		manufacturing_cost ASC LIMIT 1);
        


# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market
SELECT 
	dim_customer.customer_code, dim_customer.customer, ROUND(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct),4) as average_discount_percentage
FROM 
	dim_customer
LEFT JOIN
	fact_pre_invoice_deductions
ON
	dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
WHERE 
	dim_customer.market = 'India' AND fact_pre_invoice_deductions.fiscal_year = '2021'
GROUP BY
	dim_customer.customer_code, dim_customer.customer
 ORDER BY 
	AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct) DESC LIMIT 5;
    



# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions
SELECT
	month(fact_sales_monthly.date) as month, year(fact_sales_monthly.date) as year, SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) as gross_sales_amount
FROM 
	fact_gross_price
LEFT JOIN 
	fact_sales_monthly 
ON 
	fact_gross_price.product_code = fact_sales_monthly.product_code
GROUP BY
	month(fact_sales_monthly.date), year(fact_sales_monthly.date)
HAVING
	SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) IS NOT NULL
ORDER BY
	year(fact_sales_monthly.date) ,month(fact_sales_monthly.date);
    
    

# 8. In which quarter of 2020, got the maximum total_sold_quantity
SELECT 
	quarter(fact_sales_monthly.date) as quarter, SUM(fact_sales_monthly.sold_quantity) as quantity_sold
FROM
	fact_sales_monthly
WHERE 
	year(fact_sales_monthly.date) = 2020
GROUP BY 
	quarter(fact_sales_monthly.date)
ORDER BY 
	SUM(fact_sales_monthly.sold_quantity) DESC LIMIT 1;
    
    

# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH gross_sales_2021 AS (
SELECT
	dim_customer.channel, SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) as gross_sales_mln
FROM 
	dim_customer
LEFT JOIN 
	fact_sales_monthly
ON 
	dim_customer.customer_code = fact_sales_monthly.customer_code
LEFT JOIN
	fact_gross_price
ON
	fact_sales_monthly.product_code = fact_gross_price.product_code
WHERE
	fact_sales_monthly.fiscal_year = 2021
GROUP BY
	dim_customer.channel)
	
    SELECT
		channel, gross_sales_mln, (gross_sales_mln / SUM(gross_sales_mln) OVER ()) * 100 AS percentage
    FROM
		gross_sales_2021
	ORDER BY
		 (gross_sales_mln / SUM(gross_sales_mln) OVER ()) * 100 DESC;

        
# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH division_analysis AS (
SELECT 
	dim_product.product, dim_product.division, dim_product.product_code, SUM(fact_sales_monthly.sold_quantity) as quantity_sold, fact_sales_monthly.fiscal_year
FROM
	dim_product
LEFT JOIN
	fact_sales_monthly
ON
	dim_product.product_code = fact_sales_monthly.product_code
GROUP BY
	dim_product.division,dim_product.product_code,fact_sales_monthly.fiscal_year,dim_product.product)
    SELECT
		division, product_code,product, quantity_sold, RANK () OVER(ORDER BY quantity_sold DESC) as rank_order
	FROM
		division_analysis
	WHERE 
		fiscal_year =2021 LIMIT 3;
        
        
        
        
        



 


