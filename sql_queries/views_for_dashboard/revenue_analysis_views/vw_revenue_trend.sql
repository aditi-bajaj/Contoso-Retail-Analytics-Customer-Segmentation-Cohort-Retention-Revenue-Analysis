CREATE VIEW vw_revenue_trend AS

WITH
  monthly_sales
  AS(
      SELECT
        DATE_TRUNC('month', orderdate)::DATE AS month,
        SUM(quantity * netprice / exchangerate) AS net_revenue
      FROM sales
      WHERE orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
      GROUP BY month
  )

SELECT
  month,
  net_revenue,
  100* (net_revenue - LAG(net_revenue) OVER(ORDER BY month)) /LAG(net_revenue) OVER(ORDER BY month) AS mom_growth_percentage,
  AVG(net_revenue) OVER(ORDER BY month
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS three_month_rolling_avg,
  AVG(net_revenue) OVER(ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_avg_revenue
FROM monthly_sales ms;