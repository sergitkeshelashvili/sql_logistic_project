-- 1) Create a function and trigger to ensure shipment weight does not exceed vehicle capacity

CREATE OR REPLACE FUNCTION check_shipment_weight()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.weight_kg > (
        SELECT capacity_kg
        FROM dim_vehicles
        WHERE vehicle_id = NEW.vehicle_id
    ) THEN
        RAISE EXCEPTION 'Shipment weight % kg exceeds vehicle capacity for vehicle_id %', NEW.weight_kg, NEW.vehicle_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_shipment_weight
BEFORE INSERT OR UPDATE OF weight_kg, vehicle_id
ON fact_shipments
FOR EACH ROW
EXECUTE FUNCTION check_shipment_weight();

-- 2) Create a function and trigger to validate delivery dates are not earlier than order dates

CREATE OR REPLACE FUNCTION check_delivery_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.delivery_date < (
        SELECT order_date
        FROM dim_orders
        WHERE order_id = NEW.order_id
    ) THEN
        RAISE EXCEPTION 'Delivery date % is earlier than order date for order_id %', NEW.delivery_date, NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_delivery_date
BEFORE INSERT OR UPDATE OF delivery_date, order_id
ON fact_shipments
FOR EACH ROW
EXECUTE FUNCTION check_delivery_date();

-- 3) Create a function and trigger to prevent drivers from being assigned to overlapping shipments

CREATE OR REPLACE FUNCTION check_driver_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM fact_shipments
        WHERE driver_id = NEW.driver_id
        AND shipment_id != NEW.shipment_id
        AND (
            (NEW.pickup_date BETWEEN pickup_date AND delivery_date)
            OR
            (NEW.delivery_date BETWEEN pickup_date AND delivery_date)
            OR
            (NEW.pickup_date <= pickup_date AND NEW.delivery_date >= delivery_date)
        )
    ) THEN
        RAISE EXCEPTION 'Driver % is already assigned to another shipment during this time period', NEW.driver_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_driver_availability
BEFORE INSERT OR UPDATE OF driver_id, pickup_date, delivery_date
ON fact_shipments
FOR EACH ROW
EXECUTE FUNCTION check_driver_availability();
