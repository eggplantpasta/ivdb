CREATE TABLE IF NOT EXISTS service_schedule_override (
    service_schedule_override_id TEXT PRIMARY KEY NOT NULL,
    vehicle_id                   TEXT NOT NULL,
    service_item_id              TEXT NOT NULL,

    interval_km                  INTEGER,
    interval_months              INTEGER,
    notes                        TEXT,

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicle(vehicle_id),

    FOREIGN KEY (service_item_id)
        REFERENCES service_item(service_item_id),

    UNIQUE (vehicle_id, service_item_id)
);