CREATE OR REPLACE VIEW vw_inactive_customers AS

WITH no_purchase_customers AS
(
    SELECT
        c.customerkey,
        CONCAT_WS(' ', c.givenname, c.surname) AS customer_name,
        c.country,
        'Never Purchased' AS inactivity_type,
        NULL::DATE AS last_purchase_date
    FROM customer c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM sales s
        WHERE s.customerkey = c.customerkey
    )
),

inactive_after_2018 AS
(
    SELECT
        c.customerkey,
        CONCAT_WS(' ', c.givenname, c.surname) AS customer_name,
        c.country,
        'No Purchase After 2018' AS inactivity_type,
        MAX(s1.orderdate) AS last_purchase_date

    FROM sales s1

    JOIN customer c
        ON c.customerkey = s1.customerkey

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM sales s2
        WHERE
            s1.customerkey = s2.customerkey
            AND s2.orderdate > '2018-12-31'
    )

    GROUP BY
        c.customerkey,
        customer_name,
        c.country

    HAVING MAX(s1.orderdate)
        BETWEEN '2018-01-01' AND '2018-12-31'
)

SELECT * FROM no_purchase_customers

UNION ALL

SELECT * FROM inactive_after_2018;