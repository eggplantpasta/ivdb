CREATE TABLE IF NOT EXISTS catalogue_metadata (
    metadata_id   INTEGER PRIMARY KEY NOT NULL
                  CHECK (metadata_id = 1),
    schema_version INTEGER NOT NULL,
    data_version   INTEGER NOT NULL
);