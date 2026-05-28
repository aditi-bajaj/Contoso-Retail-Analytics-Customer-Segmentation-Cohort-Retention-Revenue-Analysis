CREATE VIEW vw_revenue_distribution AS
WITH base AS (
    SELECT 
        EXTRACT(YEAR FROM s.orderdate) AS year,
        p.categoryname AS product_category,
        s.quantity * s.netprice / s.exchangerate AS net_revenue
    FROM sales s
    JOIN product p ON p.productkey = s.productkey
    WHERE EXTRACT(YEAR FROM s.orderdate) >= 2020
),
median_calc AS (
    SELECT
        year,
        product_category,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY net_revenue) AS median_value
    FROM base
    GROUP BY product_category, year
)
SELECT 
    b.year,
    b.product_category,
    m.median_value,
    CASE
        WHEN b.net_revenue < m.median_value THEN 'Low'
        ELSE 'High'
    END AS revenue_segment,
    SUM(b.net_revenue) AS total_revenue
FROM base b
LEFT JOIN median_calc m
    ON b.product_category = m.product_category
    AND b.year = m.year
GROUP BY 
    b.year,
    b.product_category,
    m.median_value,
    revenue_segment
ORDER BY b.product_category, b.year;