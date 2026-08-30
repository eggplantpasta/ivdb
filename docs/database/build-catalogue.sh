#!/bin/sh

set -eu

script_directory=$(
    CDPATH= cd -- "$(dirname -- "$0")" && pwd
)

database_path="$script_directory/catalogue.sqlite"
resource_path="$script_directory/../../IVDB/IVDB/Resources/catalogue.sqlite"

temporary_database=$(
    mktemp "$script_directory/catalogue.sqlite.XXXXXX"
)

cleanup() {
    rm -f "$temporary_database"
}

trap cleanup EXIT

(
    cd "$script_directory"
    sqlite3 -bail "$temporary_database" < _builddb.sql
)

integrity_result=$(
    sqlite3 "$temporary_database" "PRAGMA integrity_check;"
)

if [ "$integrity_result" != "ok" ]; then
    printf '%s\n' "Catalogue integrity check failed:"
    printf '%s\n' "$integrity_result"
    exit 1
fi

foreign_key_violations=$(
    sqlite3 "$temporary_database" "PRAGMA foreign_key_check;"
)

if [ -n "$foreign_key_violations" ]; then
    printf '%s\n' "Catalogue foreign-key check failed:"
    printf '%s\n' "$foreign_key_violations"
    exit 1
fi

metadata_rows=$(
    sqlite3 "$temporary_database" "
        SELECT COUNT(*)
        FROM catalogue_metadata
        WHERE metadata_id = 1
          AND schema_version >= 1
          AND data_version >= 1;
    "
)

if [ "$metadata_rows" != "1" ]; then
    printf '%s\n' "Catalogue metadata validation failed."
    exit 1
fi

mv "$temporary_database" "$database_path"
cp "$database_path" "$resource_path"

printf '%s\n' "Built catalogue.sqlite"
printf '%s\n' "Updated IVDB app resource"