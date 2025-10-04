-- Python-SQL Project Queries

# Create the database
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

# Create Tables and load datasets
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  order_id,
  customer_id,
  order_status,
  @order_purchase_timestamp,
  @order_approved_at,
  @order_delivered_carrier_date,
  @order_delivered_customer_date,
  @order_estimated_delivery_date
)
SET
  order_purchase_timestamp     = NULLIF(@order_purchase_timestamp,''),
  order_approved_at            = NULLIF(@order_approved_at,''),
  order_delivered_carrier_date = NULLIF(@order_delivered_carrier_date,''),
  order_delivered_customer_date= NULLIF(@order_delivered_customer_date,''),
  order_estimated_delivery_date= NULLIF(@order_estimated_delivery_date,'');
  
 CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  product_id,
  product_category_name,
  @product_name_length,
  @product_description_length,
  @product_photos_qty,
  @product_weight_g,
  @product_length_cm,
  @product_height_cm,
  @product_width_cm
)
SET
  product_name_length       = NULLIF(@product_name_length,''),
  product_description_length= NULLIF(@product_description_length,''),
  product_photos_qty        = NULLIF(@product_photos_qty,''),
  product_weight_g          = NULLIF(@product_weight_g,''),
  product_length_cm         = NULLIF(@product_length_cm,''),
  product_height_cm         = NULLIF(@product_height_cm,''),
  product_width_cm          = NULLIF(@product_width_cm,'');
  
  CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  order_id,
  order_item_id,
  product_id,
  seller_id,
  @shipping_limit_date,
  @price,
  @freight_value
)
SET
  shipping_limit_date = NULLIF(@shipping_limit_date,''),
  price               = NULLIF(@price,''),
  freight_value       = NULLIF(@freight_value,'');
  
  CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payments.csv'
INTO TABLE payments
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  order_id,
  payment_sequential,
  payment_type,
  @payment_installments,
  @payment_value
)
SET
  payment_installments = NULLIF(@payment_installments,''),
  payment_value        = NULLIF(@payment_value,'');

-- =============================
-- BASIC QUERIES
-- =============================

-- 1. List all unique cities where customers are located
SELECT DISTINCT customer_city
FROM customers
ORDER BY customer_city;

-- 2. Count the number of orders placed in 2017
SELECT COUNT(*) AS total_orders_2017
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2017;

-- 3. Find the total sales per category
SELECT p.product_category_name,
       SUM(oi.price) AS total_sales
FROM order_items oi
JOIN products p 
     ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC;

-- 4. Calculate the percentage of orders that were paid in installments
SELECT 
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN payment_installments > 1 THEN order_id END)
    / COUNT(DISTINCT order_id)
  , 2) AS percent_orders_with_installments
FROM payments;

-- 5. Count the number of customers from each state
SELECT customer_state, COUNT(*) AS customer_count
FROM customers
GROUP BY customer_state
ORDER BY customer_count DESC;

-- =============================
-- INTERMEDIATE QUERIES
-- =============================

-- 1. Calculate the number of orders per month in 2018
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(*) AS total_orders
FROM orders
WHERE YEAR(order_purchase_timestamp) = 2018
GROUP BY month
ORDER BY month;

-- 2. Find the average number of products per order, grouped by customer city
SELECT customer_city,
       ROUND(AVG(item_count), 2) AS avg_products_per_order
FROM (
    SELECT o.order_id, c.customer_city, COUNT(oi.product_id) AS item_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, c.customer_city
) AS order_summary
GROUP BY customer_city
ORDER BY avg_products_per_order DESC;

-- 3. Calculate the percentage of total revenue contributed by each product category
SELECT p.product_category_name,
       ROUND(100 * SUM(oi.price) / (SELECT SUM(price) FROM order_items),2) AS revenue_percent
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue_percent DESC;

-- 4. Identify the correlation between product price and the number of times a product has been purchased
SELECT oi.product_id,
       ROUND(AVG(oi.price),2) AS avg_price,
       COUNT(*) AS times_purchased
FROM order_items oi
GROUP BY oi.product_id;
#Actual Correlation will be found using python

-- 5. Calculate the total revenue generated by each seller, and rank them by revenue
SELECT s.seller_id,
       s.seller_city,
       s.seller_state,
       SUM(oi.price) AS total_revenue,
       RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;

-- =============================
-- ADVANCED QUERIES
-- =============================

-- 1. Moving average of order values for each customer
SELECT o.customer_id,
       o.order_id,
       SUM(oi.price) AS order_value,
       ROUND(AVG(SUM(oi.price)) OVER (
           PARTITION BY o.customer_id
           ORDER BY o.order_purchase_timestamp
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp;

-- 2. Cumulative sales per month per year
SELECT YEAR(o.order_purchase_timestamp) AS order_year,
       MONTH(o.order_purchase_timestamp) AS order_month,
       SUM(oi.price) AS monthly_sales,
       SUM(SUM(oi.price)) OVER (
           PARTITION BY YEAR(o.order_purchase_timestamp)
           ORDER BY MONTH(o.order_purchase_timestamp)
       ) AS cumulative_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;

-- 3. Year-over-year growth rate of sales
WITH yearly_sales AS (
    SELECT YEAR(o.order_purchase_timestamp) AS order_year,
           SUM(oi.price) AS total_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY YEAR(o.order_purchase_timestamp)
)
SELECT order_year,
       total_sales,
       LAG(total_sales) OVER (ORDER BY order_year) AS prev_year_sales,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY order_year)) 
             / LAG(total_sales) OVER (ORDER BY order_year) * 100, 2) 
             AS yoy_growth_percent
FROM yearly_sales;

-- 4. Retention rate (customers returning within 6 months)
WITH first_orders AS (
    SELECT customer_id,
           MIN(order_purchase_timestamp) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
next_orders AS (
    SELECT o.customer_id,
           o.order_purchase_timestamp
    FROM orders o
    JOIN first_orders f ON o.customer_id = f.customer_id
    WHERE o.order_purchase_timestamp > f.first_order_date
      AND TIMESTAMPDIFF(MONTH, f.first_order_date, o.order_purchase_timestamp) <= 6
)
SELECT ROUND(COUNT(DISTINCT next_orders.customer_id) 
             / COUNT(DISTINCT first_orders.customer_id) * 100, 2) AS retention_rate_percent
FROM first_orders
LEFT JOIN next_orders ON first_orders.customer_id = next_orders.customer_id;

-- 5. Top 3 customers by spend per year
WITH yearly_customer_sales AS (
    SELECT YEAR(o.order_purchase_timestamp) AS order_year,
           o.customer_id,
           SUM(oi.price) AS customer_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY YEAR(o.order_purchase_timestamp), o.customer_id
)
SELECT order_year, customer_id, customer_sales
FROM (
    SELECT order_year, customer_id, customer_sales,
           ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY customer_sales DESC) AS rank_
    FROM yearly_customer_sales
) ranked
WHERE rank_ <= 3
ORDER BY order_year, rank_;
