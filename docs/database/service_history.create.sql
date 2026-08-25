CREATE TABLE IF NOT EXISTS service_history (
    service_history_id       TEXT PRIMARY KEY NOT NULL,
    vehicle_id               TEXT NOT NULL,
    service_item_id          TEXT NOT NULL,

    service_date             TEXT NOT NULL,
    odometer_km              INTEGER,
    performed_by             TEXT,
    cost                     REAL,
    notes                    TEXT,

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicle(vehicle_id),

    FOREIGN KEY (service_item_id)
        REFERENCES service_item(service_item_id)
);