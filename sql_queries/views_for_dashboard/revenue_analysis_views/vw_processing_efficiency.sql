CREATE VIEW vw_processing_efficiency AS
SELECT 
    EXTRACT(YEAR FROM orderdate) AS year,
    SUM(quantity * netprice / exchangerate) AS total_revenue,
    AVG(deliverydate::date - orderdate::date) AS avg_processing_time
FROM sales
GROUP BY year;