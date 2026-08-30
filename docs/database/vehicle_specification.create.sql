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
    engine                  TEXT,
    transmission            TEXT,
    is_deprecated           INTEGER NOT NULL DEFAULT 0
                            CHECK (is_deprecated IN (0, 1))
);

CREATE INDEX IF NOT EXISTS idx_vehicle_specification_make_model_years
    ON vehicle_specification (
        is_deprecated,
        make,
        model,
        year_from,
        year_to
    );