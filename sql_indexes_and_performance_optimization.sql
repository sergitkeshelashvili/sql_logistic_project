-- Primary Search Indexes
-- Index on customer_name for searches by customer name

CREATE INDEX idx_customer_name ON dim_customers (customer_name);

-- Index on shipment_id for tracking shipments

CREATE INDEX idx_shipment_id ON fact_shipments (shipment_id);

-- Composite Indexes for Common Query Patterns
-- Index for joins and filters on fact_shipments with customer_id and delivery_date

CREATE INDEX idx_shipments_customer_delivery ON fact_shipments (customer_id, delivery_date);

-- Index for joins with product_id and category filtering

CREATE INDEX idx_products_category ON dim_products (product_id, category);

-- Index for joins with route_id and distance_km

CREATE INDEX idx_routes_route_distance ON dim_routes (route_id, distance_km);

-- Index for orders with payment_method and order_date

CREATE INDEX idx_orders_payment_date ON dim_orders (payment_method, order_date);

-- Index for warehouse joins and region filtering

CREATE INDEX idx_warehouses_region ON dim_warehouses (warehouse_id, region);

-- Partial Indexes for Filtered Queries
-- Partial index for active vehicles

CREATE INDEX idx_vehicles_active ON dim_vehicles (vehicle_id) WHERE status = 'active';

-- Partial index for on-time deliveries

CREATE INDEX idx_shipments_on_time ON fact_shipments (shipment_id, delivery_date) WHERE on_time_delivery = true;

-- Partial index for damaged shipments

CREATE INDEX idx_shipments_damaged ON fact_shipments (shipment_id, product_id) WHERE damage_reported = true;

-- Performance Testing with EXPLAIN ANALYZE
-- 1) Count of customers by city and region
-- before indexing


EXPLAIN ANALYZE
SELECT
    COUNT(customer_id) AS customer_count,
    city,
    region
FROM dim_customers
GROUP BY city, region
ORDER BY COUNT(customer_id) DESC;

-- After indexing (idx_customer_name and potentially city, region)

CREATE INDEX idx_customers_city_region ON dim_customers (city, region);

EXPLAIN ANALYZE
SELECT
    COUNT(customer_id) AS customer_count,
    city,
    region
FROM dim_customers
GROUP BY city, region
ORDER BY COUNT(customer_id) DESC;

-- 2) Shipment performance metrics
-- Before indexing

EXPLAIN ANALYZE
SELECT
    ROUND((COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS damaged_delayed_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 2) AS no_damage_percentage,
    ROUND((COUNT(CASE WHEN on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS on_time_delivery_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE AND on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS no_damage_on_time_delivery_percentage,
    COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) AS damaged_and_delayed_count
FROM fact_shipments;

-- After indexing (idx_shipments_on_time and idx_shipments_damaged)

EXPLAIN ANALYZE
SELECT
    ROUND((COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS damaged_delayed_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 2) AS no_damage_percentage,
    ROUND((COUNT(CASE WHEN on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS on_time_delivery_percentage,
    ROUND((COUNT(CASE WHEN damage_reported IS FALSE AND on_time_delivery IS TRUE THEN shipment_id END) * 100.0 / COUNT(shipment_id)), 1) AS no_damage_on_time_delivery_percentage,
    COUNT(CASE WHEN damage_reported IS TRUE AND on_time_delivery IS FALSE THEN shipment_id END) AS damaged_and_delayed_count
FROM fact_shipments;

-- 3) Warehouse sales analysis 
-- Before indexing

EXPLAIN ANALYZE
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

-- After indexing (idx_warehouses_region and idx_shipments_customer_delivery)

EXPLAIN ANALYZE
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
