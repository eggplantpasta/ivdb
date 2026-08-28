CREATE TABLE IF NOT EXISTS service_item (
    service_item_id          TEXT PRIMARY KEY NOT NULL,
    name                     TEXT NOT NULL,
    description              TEXT
);

CREATE INDEX IF NOT EXISTS idx_service_item_name
    ON service_item (name);