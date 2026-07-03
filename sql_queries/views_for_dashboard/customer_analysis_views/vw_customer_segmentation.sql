CREATE OR REPLACE VIEW vw_customer_segmentation AS

WITH customer_ltv AS
(
    SELECT
        customerkey,
        customer_name,
        countryfull AS country,
        SUM(total_net_revenue) AS ltv
    FROM cohort_analysis
    GROUP BY
        customerkey,
        customer_name,
        country
),

percentiles AS
(
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ltv) AS p25th,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ltv) AS p75th
    FROM customer_ltv
),

segments AS
(
    SELECT
        cl.*,

        CASE
            WHEN cl.ltv < p.p25th THEN 'Low Value'
            WHEN cl.ltv <= p.p75th THEN 'Mid Value'
            ELSE 'High Value'
        END AS customer_segment

    FROM customer_ltv cl
    CROSS JOIN percentiles p
)

SELECT
    customerkey,
    customer_name,
    country,
    ltv,
    customer_segment
FROM segments;