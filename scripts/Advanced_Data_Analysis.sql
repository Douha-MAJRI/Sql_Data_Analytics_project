/*
================================================================================
Advanced Data Analytics: Gold Layer
================================================================================
Script Purpose: Advanced analytics queries for trends, performance, segmentation,
and contribution analysis.
It performs the following key ACTIONS:
    - Analyze time series trends by year, month, and period.
    - Compute cumulative measures for sales and price.
    - Evaluate product performance and year-over-year change.
    - Calculate part-to-whole contributions by category.
    - Segment customers and products into behavioral groups.
USAGE EXAMPLES:
    Run statements individually as needed for analysis.
================================================================================
*/

-- ================================================================
-- Change over time trends: [measure] by [date dimension]
-- ================================================================
-- Time series trends derived from the sales fact table
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_items_sold
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

SELECT
    MONTH(order_date) AS order_month,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_items_sold
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date);

SELECT
    FORMAT(order_date, 'yyyy-MMM') AS order_period,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_items_sold
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');

-- ================================================================
-- Cumulative analysis
-- ================================================================
SELECT
    order_date,
    total_sales,
    avg_selling_price,
    SUM(total_sales) OVER (ORDER BY order_date) AS cumulative_sales,
    AVG(avg_selling_price) OVER (ORDER BY order_date) AS cumulative_avg_selling_price
FROM (
    SELECT
        DATETRUNC(YEAR, order_date) AS order_date,
        SUM(sales) AS total_sales,
        AVG(price) AS avg_selling_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, order_date)
) T;

-- ================================================================
-- Performance analysis
-- ================================================================
WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales_per_year,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS sales_deviation_from_avg,
    CASE
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Average'
        ELSE 'Average'
    END AS performance_category,
    -- Year-over-year change
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS sales_change_from_previous_year,
    CASE
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Improving'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Declining'
        ELSE 'Stable'
    END AS trend_category
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- ================================================================
-- Part-to-whole analysis: [measure] / total(measure) * 100
-- ================================================================
WITH category_sales AS (
    SELECT
        category,
        SUM(sales) AS category_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY category
)
SELECT
    category,
    category_sales,
    SUM(category_sales) OVER () AS overall_sales,
    CONCAT(
        ROUND((CAST(category_sales AS FLOAT) / SUM(category_sales) OVER ()) * 100, 2),
        ' %'
    ) AS category_contribution_percentage
FROM category_sales
ORDER BY category_sales DESC;

-- ================================================================
-- Data segmentation: [measure] by [measure]
-- ================================================================
WITH customer_segments AS (
    SELECT
        f.customer_key,
        SUM(sales) AS total_sales,
        CASE
            WHEN SUM(sales) > 5000 AND DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) >= 12 THEN 'VIP Customer'
            WHEN SUM(sales) <= 5000 AND DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) >= 12 THEN 'Regular Customer'
            WHEN DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) < 12 THEN 'New Customer'
            ELSE 'Other'
        END AS customer_behavioral_segment
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
    WHERE order_date IS NOT NULL
    GROUP BY f.customer_key
)
SELECT
    customer_behavioral_segment,
    COUNT(customer_key) AS total_customers_in_segment,
    SUM(total_sales) AS total_sales_in_segment,
    AVG(total_sales) AS avg_sales_per_customer_in_segment
FROM customer_segments
GROUP BY customer_behavioral_segment
ORDER BY total_customers_in_segment DESC;

-- Product cost segmentation
SELECT
    cost_segment,
    COUNT(product_key) AS products_in_cost_segment
FROM (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost > 1000 THEN 'High Cost'
            WHEN cost BETWEEN 500 AND 1000 THEN 'Medium Cost'
            ELSE 'Low Cost'
        END AS cost_segment
    FROM gold.dim_products
) f
GROUP BY cost_segment
ORDER BY products_in_cost_segment DESC;
