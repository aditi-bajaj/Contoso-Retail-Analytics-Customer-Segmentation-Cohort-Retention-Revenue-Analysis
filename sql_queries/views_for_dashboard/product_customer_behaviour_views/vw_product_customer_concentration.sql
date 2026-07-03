CREATE OR REPLACE VIEW vw_product_customer_concentration AS

WITH main AS
(
    SELECT

        p.productkey AS product_key,

        TRIM(p.productname) AS product_name,

        s.customerkey,

        SUM(
            s.quantity * s.netprice / s.exchangerate
        )::NUMERIC AS customer_revenue,

        SUM(
            SUM(s.quantity * s.netprice / s.exchangerate)
        ) OVER(
            PARTITION BY p.productkey, p.productname
        )::NUMERIC AS total_product_revenue

    FROM sales s

    JOIN product p
        ON p.productkey = s.productkey

    GROUP BY
        product_key,
        product_name,
        s.customerkey
),

cumulative_revenue AS
(
    SELECT

        *,

        SUM(customer_revenue)
            OVER(
                PARTITION BY product_key, product_name
                ORDER BY customer_revenue DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
            AS cumulative_customer_revenue,

        ROW_NUMBER()
            OVER(
                PARTITION BY product_key, product_name
                ORDER BY customer_revenue DESC
            ) AS customer_rank

    FROM main
),

facts AS
(
    SELECT

        *,

        cumulative_customer_revenue
            / total_product_revenue
            AS cumulative_pct,

        MAX(customer_rank)
            OVER(PARTITION BY product_key)
            AS total_customers

    FROM cumulative_revenue
),

top_customers AS
(
    SELECT

        product_key,

        MIN(customer_rank) AS customers_for_50pct_revenue

    FROM facts

    WHERE cumulative_pct >= 0.5

    GROUP BY product_key
)

SELECT

    f.product_key,

    f.product_name,

    tc.customers_for_50pct_revenue,

    f.total_customers,

    f.cumulative_customer_revenue
        AS revenue_from_top_customers,

    f.total_product_revenue,

    ROUND(
        100.0
        * tc.customers_for_50pct_revenue
        / f.total_customers,
        2
    ) AS customer_pct_needed_for_50pct_revenue,

    ROUND(
        100 * f.cumulative_pct,
        2
    ) AS revenue_share_pct

FROM facts f

JOIN top_customers tc
    ON tc.product_key = f.product_key

WHERE f.customer_rank = tc.customers_for_50pct_revenue

ORDER BY
    customer_pct_needed_for_50pct_revenue,
    revenue_share_pct DESC;