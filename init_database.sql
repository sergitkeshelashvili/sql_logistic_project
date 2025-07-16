-- Create the database for the logistics project
CREATE DATABASE sql_logistics_project;

-- Create an ENUM type for customer classification (B2B or B2C)
CREATE TYPE customer_type_enum AS ENUM ('B2B', 'B2C');

-- Create the dim_customers table to store customer information
CREATE TABLE dim_customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    customer_type customer_type_enum DEFAULT 'B2B',
    email VARCHAR(50),
    phone VARCHAR(50),
    city VARCHAR(50),
    region VARCHAR(50),
    country CHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_products table to store product details
CREATE TABLE dim_products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_vehicles table to store vehicle information
CREATE TABLE dim_vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_type VARCHAR(50),
    capacity_kg DECIMAL(10,2),
    status VARCHAR(20) CHECK (status IN ('active', 'maintenance', 'retired')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_drivers table to store driver information
CREATE TABLE dim_drivers (
    driver_id SERIAL PRIMARY KEY,
    driver_firstname VARCHAR(50) NOT NULL,
    driver_lastname VARCHAR(50) NOT NULL,
    hire_date DATE,
    experience_years INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_warehouses table to store warehouse details
CREATE TABLE dim_warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    region VARCHAR(50),
    country CHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_routes table to store route information
CREATE TABLE dim_routes (
    route_id SERIAL PRIMARY KEY,
    origin_city VARCHAR(50),
    destination_city VARCHAR(50),
    distance_km DECIMAL(8,2),
    estimated_hours DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_suppliers table to store supplier information
CREATE TABLE dim_suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(50) NOT NULL,
    email VARCHAR(50),
    phone VARCHAR(50),
    city VARCHAR(50),
    region VARCHAR(50),
    country CHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_orders table to store order details
CREATE TABLE dim_orders (
    order_id SERIAL PRIMARY KEY,
    payment_method VARCHAR(30),
    order_date DATE,
    quantity_sold INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the dim_employees table to store employee information
CREATE TABLE dim_employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) NOT NULL,
    gender CHAR(20),
    salary INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the fact_shipments table to store shipment details, linking to dimension tables
CREATE TABLE fact_shipments (
    shipment_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dim_customers(customer_id),
    product_id INTEGER REFERENCES dim_products(product_id),
    vehicle_id INTEGER REFERENCES dim_vehicles(vehicle_id),
    driver_id INTEGER REFERENCES dim_drivers(driver_id),
    warehouse_id INTEGER REFERENCES dim_warehouses(warehouse_id),
    route_id INTEGER REFERENCES dim_routes(route_id),
    supplier_id INTEGER REFERENCES dim_suppliers(supplier_id),
    order_id INTEGER REFERENCES dim_orders(order_id),
    employee_id INTEGER REFERENCES dim_employees(employee_id),
    pickup_location VARCHAR(50),
    delivery_location VARCHAR(50),
    pickup_date DATE,
    delivery_date DATE,
    quantity_shipped INTEGER NOT NULL,
    weight_kg DECIMAL(10,2),
    volume_m3 DECIMAL(10,2),
    shipping_cost DECIMAL(10,2),
    on_time_delivery BOOLEAN,
    damage_reported BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert random data into dim_customers (150 records) with generated names, emails, and locations
INSERT INTO dim_customers (customer_name, customer_type, email, phone, city, region, country, created_at, updated_at)
SELECT 
    'Customer ' || n AS customer_name,
    CASE WHEN random() > 0.5 THEN 'B2B'::customer_type_enum ELSE 'B2C'::customer_type_enum END AS customer_type,
    'customer' || n || '@example.com' AS email,
    '555-0' || LPAD(n::text, 3, '0') AS phone,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS city,
    (ARRAY['NY', 'CA', 'IL', 'TX', 'AZ'])[(random() * 4 + 1)::int] AS region,
    'USA' AS country,
    CURRENT_TIMESTAMP - INTERVAL '1 year' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 150) n;

-- Insert random data into dim_products (600 records) with generated product names and categories
INSERT INTO dim_products (product_name, category, unit_price, created_at, updated_at)
SELECT 
    'Product ' || n AS product_name,
    (ARRAY['Electronics', 'Clothing', 'Food', 'Furniture', 'Books'])[(random() * 4 + 1)::int] AS category,
    (random() * 999 + 1)::DECIMAL(10,2) AS unit_price,
    CURRENT_TIMESTAMP - INTERVAL '1 year' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 600) n;

-- Insert random data into dim_vehicles (75 records) with generated vehicle types and statuses
INSERT INTO dim_vehicles (vehicle_type, capacity_kg, status, created_at, updated_at)
SELECT 
    (ARRAY['Van', 'Truck', 'Semi-Trailer', 'Pickup', 'Box Truck'])[(random() * 4 + 1)::int] AS vehicle_type,
    (random() * 20000 + 1000)::DECIMAL(10,2) AS capacity_kg,
    (ARRAY['active', 'maintenance', 'retired'])[(random() * 2 + 1)::int] AS status,
    CURRENT_TIMESTAMP - INTERVAL '2 years' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 75) n;

-- Insert random data into dim_drivers (100 records) with generated names and experience
INSERT INTO dim_drivers (driver_firstname, driver_lastname, hire_date, experience_years, created_at, updated_at)
SELECT 
    (ARRAY['John', 'Jane', 'Mike', 'Sarah', 'Tom', 'Emma'])[(random() * 5 + 1)::int] AS driver_firstname,
    (ARRAY['Smith', 'Johnson', 'Brown', 'Taylor', 'Wilson'])[(random() * 4 + 1)::int] AS driver_lastname,
    CURRENT_DATE - INTERVAL '5 years' * random() AS hire_date,
    (random() * 20 + 1)::INT AS experience_years,
    CURRENT_TIMESTAMP - INTERVAL '2 years' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 100) n;

-- Insert random data into dim_warehouses (20 records) with generated warehouse names and locations
INSERT INTO dim_warehouses (warehouse_name, city, region, country, created_at, updated_at)
SELECT 
    'Warehouse ' || n AS warehouse_name,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS city,
    (ARRAY['NY', 'CA', 'IL', 'TX', 'AZ'])[(random() * 4 + 1)::int] AS region,
    'USA' AS country,
    CURRENT_TIMESTAMP - INTERVAL '3 years' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 20) n;

-- Insert random data into dim_routes (50 records) with generated origin/destination cities and distances
INSERT INTO dim_routes (origin_city, destination_city, distance_km, estimated_hours, created_at, updated_at)
SELECT 
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS origin_city,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS destination_city,
    (random() * 3000 + 100)::DECIMAL(8,2) AS distance_km,
    (random() * 48 + 1)::DECIMAL(5,2) AS estimated_hours,
    CURRENT_TIMESTAMP - INTERVAL '1 year' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 50) n;

-- Insert random data into dim_suppliers (50 records) with generated supplier names and contact info
INSERT INTO dim_suppliers (supplier_name, email, phone, city, region, country, created_at, updated_at)
SELECT 
    'Supplier ' || n AS supplier_name,
    'supplier' || n || '@example.com' AS email,
    '555-1' || LPAD(n::text, 3, '0') AS phone,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS city,
    (ARRAY['NY', 'CA', 'IL', 'TX', 'AZ'])[(random() * 4 + 1)::int] AS region,
    'USA' AS country,
    CURRENT_TIMESTAMP - INTERVAL '2 years' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 50) n;

-- Insert random data into dim_orders (500 records) with generated payment methods and quantities
INSERT INTO dim_orders (payment_method, order_date, quantity_sold, created_at, updated_at)
SELECT 
    (ARRAY['Credit Card', 'Bank Transfer', 'Cash', 'PayPal'])[(random() * 3 + 1)::int] AS payment_method,
    CURRENT_DATE - INTERVAL '6 months' * random() AS order_date,
    (random() * 100 + 1)::INT AS quantity_sold,
    CURRENT_TIMESTAMP - INTERVAL '6 months' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 500) n;

-- Insert random data into dim_employees (100 records) with generated names, departments, and salaries
INSERT INTO dim_employees (first_name, last_name, department, gender, salary, created_at, updated_at)
SELECT 
    (ARRAY['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'])[(random() * 4 + 1)::int] AS first_name,
    (ARRAY['Adams', 'Baker', 'Clark', 'Davis', 'Evans'])[(random() * 4 + 1)::int] AS last_name,
    (ARRAY['Logistics', 'Sales', 'HR', 'IT', 'Finance'])[(random() * 4 + 1)::int] AS department,
    (ARRAY['Male', 'Female', 'Non-binary'])[(random() * 2 + 1)::int] AS gender,
    (random() * 100000 + 30000)::INT AS salary,
    CURRENT_TIMESTAMP - INTERVAL '3 years' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 100) n;

-- Insert random data into fact_shipments (1500 records) with references to dimension tables and shipment details
INSERT INTO fact_shipments (
    customer_id,
    product_id,
    vehicle_id,
    driver_id,
    warehouse_id,
    route_id,
    supplier_id,
    order_id,
    employee_id,
    pickup_location,
    delivery_location,
    pickup_date,
    delivery_date,
    quantity_shipped,
    weight_kg,
    volume_m3,
    shipping_cost,
    on_time_delivery,
    damage_reported,
    created_at,
    updated_at
)
SELECT
    c.customer_id,
    p.product_id,
    v.vehicle_id,
    d.driver_id,
    w.warehouse_id,
    r.route_id,
    s.supplier_id,
    o.order_id,
    e.employee_id,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS pickup_location,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])[(random() * 4 + 1)::int] AS delivery_location,
    (CURRENT_DATE - INTERVAL '6 months' + INTERVAL '1 day' * (random() * 180))::DATE AS pickup_date,
    (CURRENT_DATE - INTERVAL '6 months' + INTERVAL '1 day' * (random() * 180) + INTERVAL '1 day' * (random() * 5))::DATE AS delivery_date,
    (random() * 50 + 1)::INTEGER AS quantity_shipped,
    (random() * 1000 + 10)::DECIMAL(10,2) AS weight_kg,
    (random() * 10 + 1)::DECIMAL(10,2) AS volume_m3,
    (random() * 500 + 10)::DECIMAL(10,2) AS shipping_cost,
    (random() > 0.2) AS on_time_delivery,
    (random() < 0.05) AS damage_reported,
    CURRENT_TIMESTAMP - INTERVAL '6 months' * random() AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM generate_series(1, 1500) AS gs(id)
CROSS JOIN LATERAL (
    SELECT (SELECT customer_id FROM dim_customers ORDER BY random() LIMIT 1) AS customer_id
) AS c
CROSS JOIN LATERAL (
    SELECT (SELECT product_id FROM dim_products ORDER BY random() LIMIT 1) AS product_id
) AS p
CROSS JOIN LATERAL (
    SELECT (SELECT vehicle_id FROM dim_vehicles ORDER BY random() LIMIT 1) AS vehicle_id
) AS v
CROSS JOIN LATERAL (
    SELECT (SELECT driver_id FROM dim_drivers ORDER BY random() LIMIT 1) AS driver_id
) AS d
CROSS JOIN LATERAL (
    SELECT (SELECT warehouse_id FROM dim_warehouses ORDER BY random() LIMIT 1) AS warehouse_id
) AS w
CROSS JOIN LATERAL (
    SELECT (SELECT route_id FROM dim_routes ORDER BY random() LIMIT 1) AS route_id
) AS r
CROSS JOIN LATERAL (
    SELECT (SELECT supplier_id FROM dim_suppliers ORDER BY random() LIMIT 1) AS supplier_id
) AS s
CROSS JOIN LATERAL (
    SELECT (SELECT order_id FROM dim_orders ORDER BY random() LIMIT 1) AS order_id
) AS o
CROSS JOIN LATERAL (
    SELECT (SELECT employee_id FROM dim_employees ORDER BY random() LIMIT 1) AS employee_id
) AS e;















































