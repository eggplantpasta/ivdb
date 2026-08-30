CREATE TABLE IF NOT EXISTS service_item (
    service_item_id TEXT PRIMARY KEY NOT NULL,
    name            TEXT NOT NULL,
    description     TEXT,
    is_deprecated   INTEGER NOT NULL DEFAULT 0
                    CHECK (is_deprecated IN (0, 1))
);

CREATE INDEX IF NOT EXISTS idx_service_item_name
    ON service_item (is_deprecated, name);