CREATE TABLE IF NOT EXISTS vehicle_specification (
    vehicle_specification_id TEXT PRIMARY KEY NOT NULL,

    make                     TEXT NOT NULL,
    model                    TEXT NOT NULL,
    generation               TEXT,
    year_from                 INTEGER,
    year_to                   INTEGER,
    series                   TEXT,
    trim                     TEXT,
    body_type                TEXT,
    engine                   TEXT,
    transmission             TEXT
);

CREATE INDEX IF NOT EXISTS idx_vehicle_specification_make_model_years
    ON vehicle_specification (make, model, year_from, year_to);