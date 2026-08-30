-- docs/database/_builddb.sql
--
-- Creates the IVDB reference database schema and loads
-- catalogue seed data.
--
-- Usage:
--   cd docs/database
--   sqlite3 ivdb.db < _builddb.sql

PRAGMA foreign_keys = ON;

.read catalogue_metadata.create.sql
.read vehicle_specification.create.sql
.read service_item.create.sql
.read service_schedule.create.sql

.read seed.sql

PRAGMA integrity_check;
PRAGMA foreign_key_check;