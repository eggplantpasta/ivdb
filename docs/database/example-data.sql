-- docs/database/example-data.sql
--
-- Contains representative user-owned data for development and testing.
--
-- This file is not part of the application catalogue and must not be
-- loaded by _builddb.sql. Production user data is stored using SwiftData.

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- Example vehicles, service history and schedule overrides belong here.

COMMIT;