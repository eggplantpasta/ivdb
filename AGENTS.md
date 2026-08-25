# IVDB

Vehicle service tracking application for Apple platforms.

## Technology

- Swift
- SwiftUI
- SwiftData
- CloudKit/iCloud synchronisation
- Universal iPhone/iPad/macOS application

## Development principles

- Prefer standard Swift and SwiftUI idioms.
- Keep the application simple.
- Avoid unnecessary abstraction.
- SwiftData models should follow the conceptual relational model
  documented in `docs/data-model.md`.
- UUIDs are used for persistent entity identifiers.
- User data must work offline and synchronise through CloudKit.

## Database design

See `docs/database/` and `docs/data-model.md`.

The SQL schema is a conceptual design/reference. SwiftData is the
application persistence implementation.