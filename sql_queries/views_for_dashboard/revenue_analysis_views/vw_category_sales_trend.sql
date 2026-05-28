CREATE VIEW vw_category_sales_trend AS

SELECT
    p.categoryname AS product_category,
    EXTRACT(YEAR FROM s.orderdate) AS year,
    SUM(s.quantity * s.netprice / s.exchangerate) AS net_revenue
FROM sales s
JOIN product p ON s.productkey = p.productkey
WHERE EXTRACT(YEAR FROM s.orderdate) >= 2020
GROUP BY product_category, year
ORDER BY year, product_category