CREATE OR REPLACE VIEW vw_customer_loyalty_behavior AS

WITH years AS
(
    SELECT
        COUNT(DISTINCT EXTRACT(YEAR FROM orderdate)) AS num_total_years
    FROM sales
),

customer_years AS
(
    SELECT
        s.customerkey,
        COUNT(DISTINCT EXTRACT(YEAR FROM s.orderdate)) AS num_purchase_years
    FROM sales s
    GROUP BY s.customerkey
),

every_year_customers AS
(
    SELECT
        cy.customerkey,
        'Purchased Every Year' AS loyalty_type
    FROM customer_years cy
    CROSS JOIN years y
    WHERE cy.num_purchase_years = y.num_total_years
),

one_category_customers AS
(
    SELECT
        s.customerkey,
        MIN(p.categoryname) AS loyalty_type
    FROM sales s
    JOIN product p
        ON s.productkey = p.productkey
    GROUP BY s.customerkey
    HAVING COUNT(DISTINCT p.categorykey) = 1
),

one_product_customers AS
(
    SELECT
        s.customerkey,
        MIN(p.productname) AS loyalty_type
    FROM sales s
    JOIN product p
        ON s.productkey = p.productkey
    GROUP BY s.customerkey
    HAVING COUNT(DISTINCT s.productkey) = 1
),

one_store_customers AS
(
    SELECT
        s.customerkey,
        MIN(st.description) AS loyalty_type
    FROM sales s
    JOIN store st
        ON s.storekey = st.storekey
    GROUP BY s.customerkey
    HAVING COUNT(DISTINCT s.storekey) = 1
)

SELECT
    c.customerkey,
    CONCAT_WS(' ', c.givenname, c.surname) AS customer_name,
    c.country,

    CASE
        WHEN ey.customerkey IS NOT NULL THEN 'Every Year Customer'
        WHEN oc.customerkey IS NOT NULL THEN 'Single Category Customer'
        WHEN op.customerkey IS NOT NULL THEN 'Single Product Customer'
        WHEN os.customerkey IS NOT NULL THEN 'Single Store Customer'
    END AS customer_behavior_type,

    COALESCE(
        oc.loyalty_type,
        op.loyalty_type,
        os.loyalty_type,
        'All Years'
    ) AS behavior_detail

FROM customer c

LEFT JOIN every_year_customers ey
    ON c.customerkey = ey.customerkey

LEFT JOIN one_category_customers oc
    ON c.customerkey = oc.customerkey

LEFT JOIN one_product_customers op
    ON c.customerkey = op.customerkey

LEFT JOIN one_store_customers os
    ON c.customerkey = os.customerkey

WHERE
    ey.customerkey IS NOT NULL
    OR oc.customerkey IS NOT NULL
    OR op.customerkey IS NOT NULL
    OR os.customerkey IS NOT NULL;