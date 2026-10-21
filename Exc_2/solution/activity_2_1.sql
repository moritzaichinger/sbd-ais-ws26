-- A. The order with the highest price per unit.
SELECT *
FROM orders
ORDER BY price_per_unit DESC, id ASC
LIMIT 1;

-- B. The top 3 categories by total quantity sold.
SELECT product_category,
       SUM(quantity) AS total_quantity
FROM orders
GROUP BY product_category
ORDER BY total_quantity DESC, product_category ASC
LIMIT 3;

-- C. The total revenue per category.
SELECT product_category,
       SUM(quantity * price_per_unit) AS total_revenue
FROM orders
GROUP BY product_category
ORDER BY total_revenue DESC, product_category ASC;

-- D. The top 5 customers by total spending.
-- The number of orders also helps us answer E.
SELECT customer_name,
       SUM(quantity * price_per_unit) AS total_spending,
       COUNT(*) AS number_of_orders
FROM orders
GROUP BY customer_name
ORDER BY total_spending DESC, customer_name ASC
LIMIT 5;

-- E. Check how often customer names are repeated.
SELECT COUNT(*) AS total_orders,
       COUNT(DISTINCT customer_name) AS different_customer_names,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT customer_name), 2)
         AS average_orders_per_name
FROM orders;
