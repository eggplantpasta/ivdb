CREATE TABLE IF NOT EXISTS vehicle (
    vehicle_id               TEXT PRIMARY KEY NOT NULL,
    vehicle_specification_id TEXT,

    name                     TEXT NOT NULL,
    registration             TEXT,
    vin                      TEXT,
    colour                   TEXT,
    build_year               INTEGER,
    notes                    TEXT,

    FOREIGN KEY (vehicle_specification_id)
        REFERENCES vehicle_specification(vehicle_specification_id)
);