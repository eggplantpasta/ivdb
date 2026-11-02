# IVDB

Vehicle service tracking application for Apple platforms.

## Technology

- Swift
- SwiftUI
- SwiftData
- Bundled read-only SQLite catalogue
- CloudKit/iCloud synchronisation
- Universal iPhone/iPad/macOS application

## Development principles

- Prefer standard Swift and SwiftUI idioms.
- Keep the application simple.
- Avoid unnecessary abstraction.
- Data models should follow the conceptual relational model
  documented in `docs/data-model.md`.
- UUIDs are used for persistent entity identifiers.
- User data must work offline and synchronise through CloudKit.

## Database design

See `docs/database/` and `docs/data-model.md`.

The SQL schema is a conceptual design/reference. Application persistence
is split between user-owned data and application-supplied catalogue data:

- SwiftData stores only user-owned `Vehicle`, `ServiceHistory` and
  `ServiceScheduleOverride` records. These records must work offline and
  will synchronise through CloudKit/iCloud.
- A bundled read-only SQLite catalogue stores `VehicleSpecification`,
  `ServiceItem` and `ServiceSchedule`. Catalogue data is not synchronised
  through CloudKit.
- Cross-store references use stable catalogue UUIDs, not SwiftData
  relationships. Application code resolves these UUIDs against the
  catalogue, and catalogue identifiers must remain stable across updates.
- Relationships entirely within user-owned data use SwiftData
  relationships where appropriate and must support CloudKit compatibility.
