CREATE OR REPLACE VIEW vw_customer_value_distribution AS

WITH customer_ltv AS
(
    SELECT
        customerkey,
        customer_name,
        SUM(total_net_revenue)::NUMERIC AS ltv
    FROM cohort_analysis
    GROUP BY
        customerkey,
        customer_name
),

pareto_table AS
(
    SELECT
        cl.*,

        100 * SUM(cl.ltv)
            OVER(
                ORDER BY ltv DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
            / SUM(cl.ltv) OVER()
            AS cumulative_revenue_pct,

        100 * COUNT(*)
            OVER(
                ORDER BY cl.ltv DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
            / COUNT(*) OVER()
            AS cumulative_customer_pct

    FROM customer_ltv cl
),

percentiles AS
(
    SELECT
        PERCENTILE_CONT(0.9)
            WITHIN GROUP (ORDER BY ltv) AS p90th,

        PERCENTILE_CONT(0.8)
            WITHIN GROUP (ORDER BY ltv) AS p80th,

        PERCENTILE_CONT(0.7)
            WITHIN GROUP (ORDER BY ltv) AS p70th

    FROM customer_ltv
),

top_customer_revenue AS
(
    SELECT

        SUM(
            CASE
                WHEN cl.ltv >= p.p90th THEN ltv
            END
        ) AS top_10_revenue,

        SUM(
            CASE
                WHEN cl.ltv >= p.p80th THEN ltv
            END
        ) AS top_20_revenue,

        SUM(
            CASE
                WHEN cl.ltv >= p.p70th THEN ltv
            END
        ) AS top_30_revenue,

        SUM(cl.ltv) AS total_revenue

    FROM customer_ltv cl
    CROSS JOIN percentiles p
),

pareto_summary AS
(
    SELECT
        ROUND(cumulative_customer_pct, 2) AS customer_percentage,
        ROUND(cumulative_revenue_pct, 2) AS revenue_percentage
    FROM pareto_table
    WHERE cumulative_revenue_pct >= 80
    ORDER BY cumulative_customer_pct
    LIMIT 1
)

SELECT

    ps.customer_percentage AS customers_for_80pct_revenue,
    ps.revenue_percentage AS revenue_generated_pct,

    ROUND(
        (100 * tcr.top_10_revenue / tcr.total_revenue)::NUMERIC,
        2
    ) AS top_10_pct_customers_revenue_share,

    ROUND(
        (100 * tcr.top_20_revenue / tcr.total_revenue)::NUMERIC,
        2
    ) AS top_20_pct_customers_revenue_share,

    ROUND(
        (100 * tcr.top_30_revenue / tcr.total_revenue)::NUMERIC,
        2
    ) AS top_30_pct_customers_revenue_share

FROM pareto_summary ps
CROSS JOIN top_customer_revenue tcr;