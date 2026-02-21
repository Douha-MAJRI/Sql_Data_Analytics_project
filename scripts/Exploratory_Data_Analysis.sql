/*
================================================================================
Exploratory Analysis: Gold Layer (dimensions + facts)
================================================================================
Script Purpose: Lightweight exploratory queries for schema discovery and
business overview metrics.
It performs the following key ACTIONS:
    - Inspect available tables and columns.
    - Explore dimension values and date boundaries.
    - Compute high-level KPIs and summary metrics.
    - Run magnitude and ranking analyses by key dimensions.
USAGE EXAMPLES:
    Run statements individually as needed for analysis.
================================================================================
*/

-- ================================================================
-- Schema discovery
-- ================================================================
SELECT * FROM INFORMATION_SCHEMA.TABLES;

SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

-- ================================================================
-- Dimension exploration
-- ================================================================
-- Customer geography coverage
SELECT DISTINCT country
FROM gold.dim_customers;

-- Product assortment coverage (295 products, 4 categories, 37 subcategories)
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products;

-- ================================================================
-- Date boundaries and ranges
-- ================================================================
SELECT
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date,
    MIN(ship_date) AS min_ship_date,
    MAX(ship_date) AS max_ship_date,
    MIN(due_date) AS min_due_date,
    MAX(due_date) AS max_due_date,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_years_range,
    DATEDIFF(YEAR, MIN(ship_date), MAX(ship_date)) AS ship_years_range,
    DATEDIFF(YEAR, MIN(due_date), MAX(due_date)) AS due_years_range
FROM gold.fact_sales;

-- Data spans 2010 to 2014 (5 years of order history)
SELECT
    MIN(start_date) AS min_start_date,
    MAX(start_date) AS max_start_date,
    DATEDIFF(YEAR, MIN(start_date), MAX(start_date)) AS start_years_range
FROM gold.dim_products;

-- Product history spans ~10 years
SELECT
    MIN(birth_date) AS min_birth_date,
    MAX(birth_date) AS max_birth_date,
    DATEDIFF(YEAR, MIN(birth_date), GETDATE()) AS Oldest_customer_age,
    DATEDIFF(YEAR, MAX(birth_date), GETDATE()) AS Youngest_customer_age,
    AVG(DATEDIFF(YEAR, birth_date, GETDATE())) AS avg_age_years
FROM gold.dim_customers;

-- ================================================================
-- Business KPIs (high level)
-- ================================================================
-- Executive-level aggregation from the sales fact table
SELECT
    SUM(sales) AS total_sales_amount,
    SUM(quantity) AS total_items_sold,
    AVG(price) AS avg_selling_price,
    COUNT(order_number) AS total_orders,
    COUNT(DISTINCT order_number) AS total_unique_orders
FROM gold.fact_sales;

SELECT
    COUNT(DISTINCT product_name) AS number_of_products
FROM gold.dim_products;

SELECT
    COUNT(DISTINCT customer_id) AS number_of_customers
FROM gold.dim_customers;

-- Customers with at least one recorded order
SELECT
    COUNT(DISTINCT customer_key) AS number_of_customers
FROM gold.fact_sales
WHERE quantity IS NOT NULL;

-- ================================================================
-- KPI report (single table output)
-- ================================================================
SELECT 'total sales amount' AS measure_name, SUM(sales) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'total items sold' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'avg selling price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'total orders' AS measure_name, COUNT(order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'total unique orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'number of products' AS measure_name, COUNT(DISTINCT product_name) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'number of customers' AS measure_name, COUNT(DISTINCT customer_id) AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'number of customers with orders' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_sales
WHERE quantity IS NOT NULL;

-- ================================================================
-- Magnitude analysis ([measure] by [dimension])
-- ================================================================
-- Customer distribution by country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customer distribution by gender
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender;

-- Product count by category
SELECT
    category,
    COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Cost profile by category
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- Revenue by category
SELECT
    category,
    SUM(sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY category
ORDER BY total_sales DESC;

-- Customer revenue contribution
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_sales DESC;

-- Units sold by country
SELECT
    c.country,
    SUM(f.quantity) AS total_quantity_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_quantity_sold DESC;

-- ================================================================
-- Ranking analysis
-- ================================================================
-- Top 5 customers by total sales
SELECT TOP 5
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_sales DESC;

-- Bottom 5 products by total sales with rank
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_sales ASC) AS sales_rank
FROM (
    SELECT TOP 5
        p.product_key,
        p.product_name,
        SUM(f.sales) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    GROUP BY p.product_key, p.product_name
    ORDER BY total_sales ASC
) t;

-- Top 3 products by total sales
SELECT TOP 3
    p.product_key,
    p.product_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_name
ORDER BY total_sales DESC;

-- Bottom 3 customers by total sales
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_sales ASC;
