/*
================================================================================
View: gold.report_customers
================================================================================
Script Purpose: Customer-level reporting view with purchase behavior, recency,
and segmentation metrics.
It performs the following key ACTIONS:
    - Join fact sales to customer dimensions.
    - Aggregate sales and order metrics per customer.
    - Derive age groups, recency, and behavioral segments.
USAGE EXAMPLES:
    SELECT TOP 100 * FROM gold.report_customers;
================================================================================
*/

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

-- Base sales + customer attributes
WITH customers_essentials AS (
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
        DATEDIFF(year, c.birth_date, GETDATE()) AS age,
        c.country,
        c.customer_number,
        f.order_number,
        f.order_date AS order_date,
        f.product_key,
        f.sales AS sales,
        f.quantity,
        f.customer_key
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
    WHERE order_date IS NOT NULL
)

-- Aggregate customer behavior
,customer_aggregation AS (
SELECT 
    customer_key,
    customer_number,
    customer_full_name,
    age,
    COUNT(distinct order_number) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS products_purchased,
    MAX(order_date) AS last_order_date,
    DATEDIFF(month, min(order_date), MAX(order_date)) AS months_as_customer
FROM customers_essentials
GROUP BY customer_key, customer_number, customer_full_name, age)

-- Final customer report
SELECT 
    customer_key,
    customer_number,
    customer_full_name,
    age,
    CASE 
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 39 THEN '26-39'
        WHEN age BETWEEN 40 AND 60 THEN '40-60'
        ELSE 'Above 60'
    END AS age_group,
    months_as_customer,
    CASE 
        WHEN total_sales > 5000 AND months_as_customer >= 12 THEN 'VIP Customer'
        WHEN total_sales <= 5000 AND months_as_customer >= 12 THEN 'Regular Customer'
        WHEN months_as_customer < 12 THEN 'New Customer'
        ELSE 'Other' 
    END AS customer_behavioral_segment,
    last_order_date,
    DATEDIFF(month, last_order_date, GETDATE()) AS recency,
    total_orders,
    CASE 
        WHEN total_orders > 0 THEN total_sales/total_orders
        ELSE 0
    END AS avg_order_value,
        CASE WHEN months_as_customer > 0 THEN total_sales/months_as_customer
        ELSE 0 
    END AS avg_monthly_spending,
    total_quantity,
    products_purchased
FROM customer_aggregation 



