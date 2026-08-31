-- docs/database/_build_docdb.sql
--
-- Creates the IVDB document database schema and loads
-- example data.
--
-- Usage:
--   cd docs/database
--   sqlite3 ivdb-doc.sqlite < _build_docdb.sql

PRAGMA foreign_keys = ON;

.read catalogue_metadata.create.sql
.read vehicle_specification.create.sql
.read service_item.create.sql
.read service_schedule.create.sql
.read vehicle.create.sql
.read service_schedule_override.create.sql
.read service_history.create.sql

.read seed.sql
.read example-data.sql

PRAGMA integrity_check;
PRAGMA foreign_key_check;