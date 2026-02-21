/*
================================================================================
View: gold.report_products
================================================================================
Script Purpose: Product-level reporting view with sales aggregation, recency,
and performance segmentation.
It performs the following key ACTIONS:
	- Join fact sales to product dimensions.
	- Aggregate sales and customer metrics per product.
	- Derive recency, segment, and revenue metrics.
USAGE EXAMPLES:
	SELECT TOP 100 * FROM gold.report_products;
================================================================================
*/

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

-- Base sales + product attributes
WITH products_essentials AS (
	SELECT
		p.product_key,
		p.product_name,
		f.order_number AS order_number,
		f.customer_key AS customer_key,
		p.category,
		p.subcategory,
		p.cost AS cost,
		f.sales,
		f.quantity,
		f.price,
		f.order_date
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
)

-- Aggregate product performance
,product_aggregation AS (
    SELECT 
        product_key,
        product_name,
        category,
        cost,
        subcategory,
        MAX(order_date) AS last_sale_date,
        COUNT(order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales) AS total_sales,
        SUM(quantity) AS total_quantity,
        AVG(price) AS avg_price,
        DATEDIFF(month, min(order_date), GETDATE()) AS months_on_sale,
        ROUND(AVG(CAST(sales AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
	FROM products_essentials
    GROUP BY product_key, product_name, category, subcategory, cost)

-- Final product report
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	months_on_sale ,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN months_on_sale  = 0 THEN total_sales
		ELSE total_sales / months_on_sale
	END AS avg_monthly_revenue

FROM product_aggregation
