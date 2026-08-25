-- docs/database/_builddb.sql
--
-- Creates the IVDB reference database schema and loads
-- catalogue seed data.
--
-- Usage:
--   cd docs/database
--   sqlite3 ivdb.db < _builddb.sql

PRAGMA foreign_keys = ON;

.read vehicle_specification.create.sql
.read service_item.create.sql
.read vehicle.create.sql
.read service_schedule.create.sql
.read service_schedule_override.create.sql
.read service_history.create.sql

.read seed.sql

PRAGMA foreign_key_check;