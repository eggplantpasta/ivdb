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
- [x] Keep the SQL schema as the conceptual/reference model rather than accessing SQLite directly from the app

## 3. SwiftData persistence

- [x] Create `VehicleSpecification` model from `docs/data-model.md`
- [ ] Create `Vehicle` model
- [ ] Create `ServiceItem` model
- [ ] Create `ServiceSchedule` model
- [ ] Create `ServiceScheduleOverride` model
- [ ] Create `ServiceHistory` model
- [ ] Use `UUID` identifiers for persistent records
- [ ] Define SwiftData relationships between the six models
- [ ] Confirm optional relationships allow a `Vehicle` without a catalogue `VehicleSpecification`
- [x] Configure the SwiftData model container
- [ ] Verify basic local persistence by creating, quitting and reopening the app

## 4. Catalogue/reference data

- [ ] Decide how application-supplied catalogue data will be packaged and loaded
- [ ] Keep catalogue data (`VehicleSpecification`, `ServiceItem`, `ServiceSchedule`) separate from user-owned data
- [ ] Import/seed the initial Honda CR-V vehicle specification
- [ ] Import/seed service items
- [ ] Import/seed recommended service schedules
- [ ] Make catalogue loading repeatable/idempotent so app upgrades do not duplicate records
- [ ] Decide how future catalogue updates will be versioned/migrated

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
- [ ] Allow selection of an optional catalogue vehicle specification
- [ ] Allow creation of a vehicle without a matching catalogue specification
- [ ] Capture name, registration, VIN, colour, build year and notes
- [ ] Validate required fields and sensible year values
- [ ] Create vehicle detail view

## 7. Service history

- [ ] Display service history for a vehicle
- [ ] Sort service history sensibly, newest first by default
- [ ] Record a service history item
- [ ] Select the applicable `ServiceItem`
- [ ] Capture service date
- [ ] Capture optional odometer kilometres
- [ ] Capture optional `performedBy`
- [ ] Capture optional cost
- [ ] Capture optional notes
- [ ] Edit a service history item
- [ ] Delete a service history item with confirmation
- [ ] Confirm one history record represents one maintenance action rather than a workshop visit

## 8. Service schedules and due calculations

- [ ] Display the recommended service schedule for a vehicle specification
- [ ] Implement vehicle-specific `ServiceScheduleOverride` records
- [ ] Add/edit/remove a schedule override
- [ ] Resolve effective schedule: vehicle override first, otherwise specification default
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

- [ ] Identify which SwiftData models are user-owned and should synchronise (`Vehicle`, `ServiceHistory`, `ServiceScheduleOverride`)
- [ ] Confirm catalogue/reference data should remain application-supplied rather than being copied into each user's iCloud store
- [ ] Enable iCloud and CloudKit capabilities in the Xcode project
- [ ] Configure the CloudKit container
- [ ] Configure SwiftData persistence for CloudKit-compatible synchronisation
- [ ] Review model relationships and constraints for SwiftData/CloudKit compatibility
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

- [ ] Add unit tests for effective schedule selection
- [ ] Add unit tests for next-due date calculations
- [ ] Add unit tests for next-due odometer calculations
- [ ] Test null/missing odometer values
- [ ] Test vehicles without a catalogue specification
- [ ] Test schedule overrides
- [ ] Test create/edit/delete flows for user-owned records
- [ ] Add representative development/sample data for UI testing
- [ ] Test persistence across app launches
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
