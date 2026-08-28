CREATE TABLE IF NOT EXISTS service_schedule (
    service_schedule_id      TEXT PRIMARY KEY NOT NULL,
    vehicle_specification_id TEXT NOT NULL,
    service_item_id          TEXT NOT NULL,

    interval_km              INTEGER,
    interval_months          INTEGER,
    notes                    TEXT,

    FOREIGN KEY (vehicle_specification_id)
        REFERENCES vehicle_specification(vehicle_specification_id),

    FOREIGN KEY (service_item_id)
        REFERENCES service_item(service_item_id),

    UNIQUE (vehicle_specification_id, service_item_id)
);

CREATE INDEX IF NOT EXISTS idx_service_schedule_service_item
    ON service_schedule (service_item_id);