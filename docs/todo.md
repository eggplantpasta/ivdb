# IVDB TODO

## 1. Development environment

- [x] Open Xcode for the first time and complete any additional component installation
- [x] Confirm the iOS Simulator is installed and can launch a current iPhone simulator
- [x] Sign in to Xcode with Apple ID / developer account if required
- [x] Create the IVDB Xcode project using Swift and SwiftUI
- [x] Set a sensible bundle identifier
- [x] Add the Xcode project to the existing IVDB Git repository
- [x] Confirm Xcode-generated files and `.gitignore` are appropriate
- [x] Build and run the starter app in the iOS Simulator
- [x] Commit the initial working Xcode project

## 2. Database reference model

- [x] Update seed.sql with realistic Honda CR-V service items and schedules
- [x] Build reference database using `_builddb.sql`
- [x] Check database with `PRAGMA foreign_key_check`
- [x] Review resulting seed data
- [x] Review `docs/data-model.md` against the SQL schema before implementing SwiftData models
- [x] Keep the SQL schema as the conceptual relational model and design reference
- [x] Confirm the catalogue schema contains only `VehicleSpecification`, `ServiceItem` and `ServiceSchedule` data
- [x] Keep development/test user data in `example-data.sql`, separate from catalogue seed data

## 3. SwiftData persistence

- [x] Prototype all six conceptual entities as SwiftData models: `VehicleSpecification`, `Vehicle`, `ServiceItem`, `ServiceSchedule`, `ServiceScheduleOverride` and `ServiceHistory`
- [x] Configure the SwiftData model container
- [x] Remove `VehicleSpecification`, `ServiceItem` and `ServiceSchedule` from the SwiftData schema/model container
- [x] Retain/refactor only `Vehicle`, `ServiceHistory` and `ServiceScheduleOverride` as SwiftData models
- [x] Use `UUID` identifiers for all user-owned SwiftData records
- [x] Represent `Vehicle.vehicleSpecificationId` as an optional stable catalogue UUID, not a SwiftData relationship
- [x] Represent `ServiceHistory.serviceItemId` and `ServiceScheduleOverride.serviceItemId` as stable catalogue UUIDs, not SwiftData relationships
- [x] Define SwiftData relationships only within user-owned data, including history and overrides belonging to a vehicle
- [x] Confirm a `Vehicle` can be stored without a catalogue `VehicleSpecification`
- [x] Plan migration/compatibility for any development data created with the original six-model SwiftData prototype
- [x] Verify basic local persistence by creating, quitting and reopening the app

## 4. Catalogue/reference data

- [x] Define Swift value types/DTOs for catalogue `VehicleSpecification`, `ServiceItem` and `ServiceSchedule` rows without making them SwiftData models
- [x] Build `catalogue.sqlite` from the catalogue schema and seed/import sources before application distribution
- [x] Populate `catalogue.sqlite` with the initial Honda CR-V vehicle specifications
- [x] Populate `catalogue.sqlite` with service items and recommended service schedules
- [x] Validate the built catalogue with `PRAGMA foreign_key_check` and automated integrity checks
- [x] Add indexes for vehicle-specification browsing/search, service-item lookup and schedule lookup by vehicle specification/service item
- [x] Verify representative catalogue queries with `EXPLAIN QUERY PLAN`
- [x] Add `catalogue.sqlite` to the application bundle and verify it is present in iPhone, iPad and macOS builds
- [x] Open the bundled catalogue read-only at runtime without copying or importing it into SwiftData
- [x] Implement a small catalogue query layer for lookup by UUID and for vehicle/service selection lists
- [x] Ensure query code handles a missing, unreadable or incompatible catalogue gracefully
- [x] Assign deterministic, stable UUIDs to every catalogue record
- [x] Ensure catalogue UUIDs never change when the database is rebuilt or an existing record is updated
- [x] Add explicit catalogue schema/data version metadata
- [x] Define compatibility rules for replacing `catalogue.sqlite` in application updates while preserving UUID references held by user data
- [x] Decide how removed/deprecated catalogue records remain resolvable, or how unresolved UUIDs are represented in the UI
- [ ] Add a repeatable catalogue build command/script suitable for local development and release builds

## 5. Basic app structure and navigation

- [ ] Decide initial navigation structure for iPhone/iPad
- [ ] Create the main vehicle list screen
- [ ] Add an empty-state view when no vehicles exist
- [ ] Add navigation from vehicle list to vehicle detail
- [ ] Add a Settings/About area if needed
- [ ] Check layouts on more than one iPhone simulator size
- [ ] Check basic iPad layout

## 6. Vehicle management

- [ ] Display user vehicles
- [ ] Add a vehicle
- [ ] Edit a vehicle
- [ ] Delete a vehicle with confirmation
- [ ] Query `catalogue.sqlite` for vehicle specification selection and search
- [ ] Store the selected specification's stable UUID in `Vehicle.vehicleSpecificationId`
- [ ] Resolve `vehicleSpecificationId` through the catalogue query layer when displaying a vehicle
- [ ] Handle a missing/unresolved catalogue specification UUID without losing the user's vehicle data
- [ ] Allow creation of a vehicle without a matching catalogue specification
- [ ] Capture name, registration, VIN, colour, build year and notes
- [ ] Validate required fields and sensible year values
- [ ] Create vehicle detail view

## 7. Service history

- [ ] Display service history for a vehicle
- [ ] Sort service history sensibly, newest first by default
- [ ] Record a service history item
- [ ] Query `catalogue.sqlite` to select the applicable `ServiceItem`
- [ ] Store the selected service item's stable UUID in `ServiceHistory.serviceItemId`
- [ ] Resolve service item UUIDs through the catalogue query layer when displaying history
- [ ] Handle a missing/unresolved service item UUID without losing the history record
- [ ] Capture service date
- [ ] Capture optional odometer kilometres
- [ ] Capture optional `performedBy`
- [ ] Capture optional cost
- [ ] Capture optional notes
- [ ] Edit a service history item
- [ ] Delete a service history item with confirmation
- [ ] Confirm one history record represents one maintenance action rather than a workshop visit

## 8. Service schedules and due calculations

- [ ] Resolve a vehicle's optional catalogue specification UUID before loading its recommended schedule
- [ ] Query `catalogue.sqlite` for the recommended service schedule and associated service items
- [ ] Display the recommended service schedule for a resolved vehicle specification
- [ ] Implement vehicle-specific `ServiceScheduleOverride` records
- [ ] Store each override's catalogue service item as a stable UUID
- [ ] Add/edit/remove a schedule override
- [ ] Resolve override service item UUIDs and catalogue schedule rows through the catalogue query layer
- [ ] Resolve effective schedule across both stores: SwiftData vehicle override first, otherwise SQLite catalogue default
- [ ] Handle missing/unresolved catalogue UUIDs and vehicles without a catalogue specification
- [ ] Find the latest applicable service history record for each scheduled service item
- [ ] Calculate next due odometer from last-service odometer + interval kilometres
- [ ] Calculate next due date from last-service date + interval months
- [ ] Treat a service as due when either distance or time threshold is reached first
- [ ] Handle schedules containing only kilometres or only months
- [ ] Handle service items with no fixed schedule
- [ ] Do not persist calculated next-due values as authoritative data
- [ ] Create an upcoming/due service view
- [ ] Distinguish overdue, due soon and not-yet-due items in the UI
- [ ] Decide how to calculate distance-based due status when the vehicle's current odometer is unknown

## 9. iCloud / CloudKit synchronisation

- [x] Identify the user-owned SwiftData models that should synchronise: `Vehicle`, `ServiceHistory` and `ServiceScheduleOverride`
- [x] Confirm `VehicleSpecification`, `ServiceItem` and `ServiceSchedule` remain in the bundled catalogue and are not copied into iCloud
- [ ] Enable iCloud and CloudKit capabilities in the Xcode project
- [ ] Configure the CloudKit container
- [ ] Configure the user-owned SwiftData model container for CloudKit-compatible synchronisation
- [ ] Verify the CloudKit schema contains only `Vehicle`, `ServiceHistory` and `ServiceScheduleOverride`
- [ ] Review user-owned relationships and constraints for SwiftData/CloudKit compatibility
- [ ] Confirm catalogue UUID reference fields synchronise as scalar values and resolve locally against each app version's bundled catalogue
- [ ] Confirm `catalogue.sqlite` is never uploaded to or synchronised by CloudKit
- [ ] Test creating data while offline
- [ ] Test synchronisation between two simulator/device instances where practical
- [ ] Test conflict behaviour for records edited on multiple devices
- [ ] Confirm app remains usable without a network connection

## 10. UI polish and accessibility

- [ ] Use standard SwiftUI controls and navigation patterns where possible
- [ ] Add appropriate SF Symbols/icons
- [ ] Support light and dark appearance
- [ ] Check Dynamic Type / larger text sizes
- [ ] Add useful accessibility labels where controls are not self-explanatory
- [ ] Check VoiceOver navigation on key screens
- [ ] Check forms with keyboard and validation errors
- [ ] Add app icon and basic branding

## 11. Testing

- [ ] Add tests for catalogue database build integrity, version metadata and stable UUIDs
- [ ] Add tests for catalogue indexes and representative queries
- [ ] Add tests for catalogue UUID lookup/resolution from each user-owned model
- [ ] Test missing/unresolved catalogue UUID behaviour across vehicle, history and schedule views
- [ ] Add unit tests for effective schedule selection
- [ ] Add unit tests for next-due date calculations
- [ ] Add unit tests for next-due odometer calculations
- [ ] Test null/missing odometer values
- [ ] Test vehicles without a catalogue specification
- [ ] Test schedule overrides
- [ ] Test create/edit/delete flows for user-owned records
- [ ] Add representative development/sample data for UI testing
- [ ] Test persistence across app launches
- [ ] Test that replacing the bundled catalogue with a compatible newer version preserves user-data references
- [ ] Test on a physical iPhone
- [ ] Test on a physical iPad if available

## 12. Distribution

- [ ] Review app identifier, version and build numbering
- [ ] Configure signing for physical-device testing
- [ ] Create an App Store Connect app record when ready
- [ ] Prepare privacy information, noting that vehicle/service data is intended to remain in the user's iCloud account
- [ ] Create a TestFlight build
- [ ] Install and test via TestFlight
- [ ] Decide whether IVDB will remain personal/TestFlight-only or be prepared for App Store release

## Later

- [ ] Verify Honda CR-V service schedule against authoritative Australian data
- [ ] Consider additional vehicle catalogue data
- [ ] Consider local notifications for upcoming service items
- [ ] Consider importing/exporting user service data
- [ ] Consider attaching receipts/documents if a real requirement emerges
