
-- 1) Count of customers by city and region
-- Counts the number of customers per city and region, ordered by count in descending order to identify key customer locations

SELECT
    COUNT(customer_id) AS customer_count,
    city,
    region
FROM dim_customers
GROUP BY city, region
ORDER BY COUNT(customer_id) DESC;

-- 2) Count of suppliers by city and region
-- Counts the number of suppliers per city and region, ordered by count in descending order to identify key supplier locations

SELECT
    COUNT(supplier_id) AS supplier_count,
    city,
    region
FROM dim_suppliers
GROUP BY city, region
ORDER BY COUNT(supplier_id) DESC;

-- 3) Vehicle types sorted by capacity
-- Lists vehicles with their types and capacities, ordered by capacity in descending order to show highest-capacity vehicles

SELECT
    vehicle_id,
    vehicle_type,
    capacity_kg
FROM dim_vehicles
GROUP BY vehicle_id, vehicle_type, capacity_kg
ORDER BY capacity_kg DESC;

-- 4) Earliest and latest order dates
-- Retrieves the earliest (MIN) and latest (MAX) order dates from the orders table to show the order date range

SELECT
    MAX(order_date) AS last_order_date,
    MIN(order_date) AS first_order_date
FROM dim_orders;

-- 5) Shipment performance metrics
-- Calculates percentages for damaged/delayed, no-damage, on-time, and no-damage-on-time shipments to evaluate operational performance

SELECT
    ROUND((COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS damaged_delayed_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 2) AS no_damage_percentage,
    ROUND((COUNT(CASE WHEN on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS on_time_delivery_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE AND on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS no_damage_on_time_delivery_percentage,
    COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) AS damaged_and_delayed_count
FROM fact_shipments;

-- 6) Top orders with PayPal payment method
-- Retrieves the top 10 orders paid via PayPal, ordered by quantity sold in descending order to analyze PayPal usage

SELECT
    order_id,
    payment_method,
    quantity_sold
FROM dim_orders
WHERE payment_method = 'PayPal'
GROUP BY order_id, payment_method, quantity_sold
ORDER BY quantity_sold DESC
LIMIT 10;

-- 7) Damaged products by category
-- Counts damaged products per product name and category, ranking them within each category to identify problem-prone products

WITH damaged_product_data AS (
    SELECT
        COUNT(p.product_id) AS damaged_product_num,
        p.product_name,
        p.category
    FROM dim_products p
    LEFT JOIN fact_shipments f ON p.product_id = f.product_id
    WHERE damage_reported IS TRUE
    GROUP BY p.product_name, p.category
)
SELECT
    product_name,
    category,
    damaged_product_num,
    RANK() OVER (PARTITION BY category ORDER BY damaged_product_num DESC) AS damaged_product_num_rank
FROM damaged_product_data;

-- 8) Warehouse sales analysis
-- Calculates total sales per warehouse and ranks them by total sales to identify top-performing warehouses

WITH warehouse_data AS (
    SELECT
        w.warehouse_id,
        w.warehouse_name,
        w.region,
        SUM(o.quantity_sold * p.unit_price) AS total_sales
    FROM dim_warehouses w
    LEFT JOIN fact_shipments f ON f.warehouse_id = w.warehouse_id
    LEFT JOIN dim_orders o ON o.order_id = f.order_id
    LEFT JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY w.warehouse_id, w.warehouse_name, w.region
)
SELECT
    warehouse_id,
    warehouse_name,
    region,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS total_sales_rank
FROM warehouse_data;

-- 9) Sales analytics by product category and payment method
-- Calculates total sales per order and aggregates sales by product category and payment method using window functions to analyze sales patterns

WITH sales_analytics AS (
    SELECT
        o.order_id,
        p.product_name,
        p.category,
        o.payment_method,
        SUM(o.quantity_sold * p.unit_price) AS total_sales
    FROM fact_shipments f
    JOIN dim_orders o ON o.order_id = f.order_id
    JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY o.order_id, p.product_name, p.category, o.payment_method
)
SELECT
    order_id,
    product_name,
    category,
    payment_method,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_by_product_category,
    SUM(total_sales) OVER (PARTITION BY payment_method ORDER BY total_sales DESC) AS sales_by_payment_method,
    SUM(total_sales) OVER (PARTITION BY category, payment_method) AS sales_by_category_and_payment_method
FROM sales_analytics;

-- 10) Sales rank by category and payment method
-- Ranks orders by total sales within each product category and payment method to identify top-performing orders

WITH sales_analytics AS (
    SELECT
        o.order_id,
        p.product_name,
        p.category,
        o.payment_method,
        SUM(o.quantity_sold * p.unit_price) AS total_sales_amount
    FROM fact_shipments f
    JOIN dim_orders o ON o.order_id = f.order_id
    JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY o.order_id, p.product_name, p.category, o.payment_method
)
SELECT
    order_id,
    product_name,
    category,
    payment_method,
    total_sales_amount,
    RANK() OVER (PARTITION BY category ORDER BY total_sales_amount DESC) AS total_sales_rank_by_category,
    RANK() OVER (PARTITION BY payment_method ORDER BY total_sales_amount DESC) AS total_sales_rank_by_payment_method
FROM sales_analytics;

-- 11) Daily shipping volume by customer type
-- Calculates daily shipment counts and volumes by customer type and region, ranking them within regions to assess customer activity

WITH customer_type_daily_shipping_volume AS (
    SELECT
        c.region AS customer_region,
        c.customer_name,
        c.customer_type,
        DATE(f.delivery_date) AS shipment_date,
        COUNT(f.shipment_id) AS shipment_count,
        SUM(quantity_shipped) AS daily_shipping_volume
    FROM fact_shipments f
    JOIN dim_customers c ON f.customer_id = c.customer_id
    GROUP BY c.region, c.customer_name, c.customer_type, DATE(f.delivery_date)
    ORDER BY c.region, shipment_date
)
SELECT
    customer_region,
    customer_name,
    customer_type,
    shipment_date,
    shipment_count,
    daily_shipping_volume,
    RANK() OVER (PARTITION BY customer_region ORDER BY daily_shipping_volume DESC) AS daily_shipping_rank_by_customer_type
FROM customer_type_daily_shipping_volume;

-- 12) Driver performance analysis
-- Evaluates driver performance based on successful (on-time, undamaged) shipments, ranking by quantity shipped and distance driven

WITH driver_performance AS (
    SELECT
        d.driver_id,
        d.driver_firstname,
        d.experience_years,
        COUNT(f.shipment_id) AS total_shipments,
        SUM(f.quantity_shipped) AS total_quantity_shipped,
        SUM(r.distance_km) AS total_km_driven
    FROM fact_shipments f
    JOIN dim_drivers d ON f.driver_id = d.driver_id
    JOIN dim_routes r ON f.route_id = r.route_id
    WHERE on_time_delivery IS TRUE AND damage_reported IS FALSE
    GROUP BY d.driver_id, d.driver_firstname, d.experience_years
)
SELECT
    driver_firstname,
    experience_years,
    total_shipments,
    total_quantity_shipped,
    total_km_driven,
    RANK() OVER (ORDER BY total_quantity_shipped DESC) AS total_quantity_shipped_rank,
    RANK() OVER (ORDER BY total_km_driven DESC) AS total_km_driven_rank
FROM driver_performance;

-- 13) Vehicle performance and maintenance metrics
-- Analyzes vehicle usage (shipments, distance, load metrics) and ranks vehicles by shipments, distance, and hours to inform maintenance schedules

WITH vehicles_performance AS (
    SELECT
        v.vehicle_id,
        v.vehicle_type,
        v.capacity_kg,
        v.status,
        COUNT(f.shipment_id) AS total_shipments,
        SUM(r.distance_km) AS total_km_driven,
        SUM(r.estimated_hours) AS total_estimated_hours,
        ROUND(AVG(f.weight_kg), 2) AS avg_load_weight_kg,
        ROUND(AVG(f.volume_m3), 2) AS avg_load_volume_m3
    FROM fact_shipments f
    JOIN dim_vehicles v ON v.vehicle_id = f.vehicle_id
    JOIN dim_routes r ON f.route_id = r.route_id
    GROUP BY v.vehicle_id, v.vehicle_type, v.capacity_kg, v.status
)
SELECT
    vehicle_id,
    vehicle_type,
    capacity_kg,
    status,
    total_shipments,
    total_km_driven,
    total_estimated_hours,
    avg_load_weight_kg,
    avg_load_volume_m3,
    RANK() OVER (ORDER BY total_shipments DESC) AS total_shipments_rank_by_vehicle_type,
    RANK() OVER (ORDER BY total_km_driven DESC) AS total_km_driven_rank_by_vehicle_type,
    RANK() OVER (ORDER BY total_estimated_hours DESC) AS total_estimated_hours_rank_by_vehicle_type
FROM vehicles_performance;

-- 14) Route profitability analysis
-- Calculates revenue, shipping costs, and profit per route, ranking routes by profit to identify most profitable routes

WITH routes_rating AS (
    SELECT
        r.route_id,
        r.origin_city || ' to ' || r.destination_city AS route_name,
        r.distance_km,
        COUNT(f.shipment_id) AS total_shipments,
        SUM(f.shipping_cost) AS total_shipping_cost,
        SUM(o.quantity_sold * p.unit_price) AS total_revenue,
        SUM((o.quantity_sold * p.unit_price) - f.shipping_cost) AS total_profit
    FROM fact_shipments f
    LEFT JOIN dim_routes r ON f.route_id = r.route_id
    LEFT JOIN dim_orders o ON o.order_id = f.order_id
    LEFT JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_km
)
SELECT
    route_id,
    route_name,
    distance_km,
    total_shipments,
    total_revenue,
    total_shipping_cost,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS total_profit_rank_by_route
FROM routes_rating;

-- 15) Route optimization recommendations
-- Analyzes route efficiency by calculating cost per kilometer and ranking routes by total shipping cost to suggest optimization

WITH route_data AS (
    SELECT
        r.route_id,
        r.origin_city || ' to ' || r.destination_city AS route_name,
        r.distance_km,
        r.estimated_hours,
        COUNT(f.shipment_id) AS total_shipments,
        SUM(f.shipping_cost) AS total_shipping_cost,
        ROUND(SUM(f.shipping_cost) / r.distance_km, 2) AS cost_per_km
    FROM fact_shipments f
    JOIN dim_routes r ON f.route_id = r.route_id
    GROUP BY r.route_id, r.origin_city, r.destination_city, r.distance_km, r.estimated_hours
)
SELECT
    route_id,
    route_name,
    distance_km,
    estimated_hours,
    total_shipments,
    total_shipping_cost,
    cost_per_km,
    RANK() OVER (ORDER BY total_shipping_cost DESC) AS total_shipping_cost_rank
FROM route_data;

-- 16) Seasonal demand forecasting
-- Analyzes historical shipment data to identify seasonal demand patterns, ranking months by shipment count and quantity for forecasting

WITH monthly_demand AS (
    SELECT
        EXTRACT(YEAR FROM delivery_date) AS year,
        EXTRACT(MONTH FROM delivery_date) AS month,
        TO_CHAR(delivery_date, 'Mon') AS month_name,
        COUNT(shipment_id) AS shipment_count,
        ROUND(AVG(quantity_shipped), 2) AS avg_quantity_shipped
    FROM fact_shipments
    WHERE delivery_date IS NOT NULL
        AND quantity_shipped IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM delivery_date), EXTRACT(MONTH FROM delivery_date), TO_CHAR(delivery_date, 'Mon')
)
SELECT
    month_name,
    year,
    ROUND(AVG(shipment_count), 2) AS avg_shipment_count,
    ROUND(AVG(avg_quantity_shipped), 2) AS avg_quantity_shipped,
    RANK() OVER (ORDER BY AVG(shipment_count) DESC) AS shipment_count_rank,
    RANK() OVER (ORDER BY AVG(avg_quantity_shipped) DESC) AS quantity_rank
FROM monthly_demand
GROUP BY month_name, year
ORDER BY month_name, year;

-- 17) Monthly revenue trends by customer segment
-- Calculates monthly revenue by customer type and includes a three-month moving average to analyze revenue trends

WITH monthly_revenue AS (
    SELECT
        c.customer_type,
        TO_CHAR(f.delivery_date, 'YYYY-MM') AS year_month,
        EXTRACT(YEAR FROM f.delivery_date) AS year,
        EXTRACT(MONTH FROM f.delivery_date) AS month,
        SUM(o.quantity_sold * p.unit_price) AS monthly_revenue
    FROM fact_shipments f
    LEFT JOIN dim_customers c ON c.customer_id = f.customer_id
    LEFT JOIN dim_orders o ON o.order_id = f.order_id
    LEFT JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY c.customer_type, TO_CHAR(f.delivery_date, 'YYYY-MM'), EXTRACT(YEAR FROM f.delivery_date), EXTRACT(MONTH FROM f.delivery_date)
    ORDER BY c.customer_type, year_month
)
SELECT
    customer_type,
    year_month,
    year,
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(monthly_revenue) OVER (
            PARTITION BY customer_type
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS three_month_revenue_moving_avg_sum
FROM monthly_revenue
ORDER BY customer_type, year_month;

-- 18) Month-over-month sales change
-- Calculates monthly sales and uses the LAG function to compute the month-over-month sales change

SELECT
    order_month,
    current_month_sales,
    previous_month_sales,
    current_month_sales - previous_month_sales AS month_over_month_change
FROM (
    SELECT
        EXTRACT(MONTH FROM order_date) AS order_month,
        SUM(quantity_sold * unit_price) AS current_month_sales,
        LAG(SUM(quantity_sold * unit_price)) OVER (ORDER BY EXTRACT(MONTH FROM order_date)) AS previous_month_sales
    FROM dim_orders o
    LEFT JOIN fact_shipments f ON o.order_id = f.order_id
    LEFT JOIN dim_products p ON p.product_id = f.product_id
    GROUP BY EXTRACT(MONTH FROM order_date)
) t;

-- 19) Highest and lowest sales per product
-- Calculates sales per product and uses window functions to identify the highest and lowest sales for each product

WITH sales_stats AS (
    SELECT
        o.order_id,
        p.product_id,
        p.product_name,
        quantity_sold * unit_price AS sales
    FROM dim_orders o
    LEFT JOIN fact_shipments f ON o.order_id = f.order_id
    LEFT JOIN dim_products p ON p.product_id = f.product_id
)
SELECT
    order_id,
    product_id,
    product_name,
    sales,
    FIRST_VALUE(sales) OVER (PARTITION BY product_id ORDER BY sales) AS lowest_sales,
    FIRST_VALUE(sales) OVER (PARTITION BY product_id ORDER BY sales DESC) AS highest_sales
FROM sales_stats;
