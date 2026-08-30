# IVDB Data Model

## Purpose

IVDB is a simple vehicle service tracking application for Apple
platforms.

The application is primarily intended to record individual maintenance
events for vehicles owned by the user. The design also supports shipping
a catalogue of vehicle specifications and recommended service schedules
with the application.

The SQL schema in `docs/database/` is the **conceptual relational model
and design reference**.

Catalogue/reference data will be supplied with the application in a
bundled SQLite database. User-owned data will be persisted using
SwiftData and is intended to synchronise between the user's devices
using CloudKit/iCloud.

The model is deliberately kept small and conventional.

## Design principles

- Keep the model simple.
- One service history record represents one maintenance action;
  service actions are not grouped into workshop visits.
- Separate generic vehicle/model information from an individual user's
  vehicle.
- Separate application-supplied catalogue data from user-owned data.
- Allow a vehicle to exist even when its model is not present in the
  supplied vehicle catalogue.
- Recommended schedules belong to a vehicle specification.
- Users may override the recommended schedule for an individual
  vehicle.
- Do not store calculated "next due" values when they can be derived
  from service history and schedule data.
- Use UUIDs for persistent identifiers so records can be safely
  created independently on multiple devices.
- The SQL design is a reference model; Swift code should use normal
  Swift naming and appropriate persistence mechanisms rather than
  attempting to reproduce SQL mechanically.
- References from user-owned data to catalogue data use stable UUIDs
  rather than SwiftData relationships.

## Entities

The conceptual model contains six entities:

1. `vehicle_specification`
2. `vehicle`
3. `service_item`
4. `service_schedule`
5. `service_schedule_override`
6. `service_history`

These entities are divided between application-supplied catalogue data
and user-owned data.

## Relationships

Conceptually:

```text
vehicle_specification
        |
        +----< service_schedule >---- service_item
        |
        +----< vehicle
                   |
                   +----< service_history >---- service_item
                   |
                   +----< service_schedule_override >---- service_item
```

A `vehicle_specification` describes a generic type of vehicle.

A `vehicle` describes an actual vehicle owned by the user.

A `service_item` describes a type of maintenance operation.

A `service_schedule` associates a service item with the recommended
interval for a generic vehicle specification.

A `service_schedule_override` allows the user to replace a recommended
interval for one particular vehicle.

A `service_history` row records one maintenance action actually
performed on one vehicle.

The diagram above describes the conceptual relationships. In the
application implementation, relationships that cross the boundary
between catalogue data and user-owned data are represented using stable
UUID references rather than persistence-layer relationships.

---

## vehicle_specification

### Purpose

Represents a generic vehicle model/variant rather than an individual
physical vehicle.

Examples include a particular generation, series, engine and
transmission combination of a Honda CR-V.

Vehicle specifications are catalogue/reference data and may be supplied
with the application.

### Conceptual columns

```sql
vehicle_specification_id TEXT PRIMARY KEY NOT NULL
make                     TEXT NOT NULL
model                    TEXT NOT NULL
generation               TEXT
year_from                 INTEGER
year_to                   INTEGER
series                    TEXT
trim                      TEXT
body_type                 TEXT
engine                    TEXT
transmission              TEXT
```

### Notes

The specification needs to be detailed enough to distinguish variants
that have different maintenance requirements.

`year_from` and `year_to` describe the applicability of the
specification. An individual vehicle may additionally store its actual
build year.

The catalogue does not need to contain every possible vehicle. A user
must be able to create a vehicle without selecting a specification.

Vehicle specification identifiers must remain stable between catalogue
versions because user-owned vehicle records may refer to them.

---

## vehicle

### Purpose

Represents an actual vehicle owned or maintained by the user.

This is user-owned data and is expected to synchronise through iCloud.

### Conceptual columns

```sql
vehicle_id               TEXT PRIMARY KEY NOT NULL
vehicle_specification_id TEXT
name                     TEXT NOT NULL
registration             TEXT
vin                      TEXT
colour                   TEXT
build_year               INTEGER
notes                    TEXT
```

### Relationships

- Optionally refers to one catalogue `vehicle_specification` by stable
  UUID.
- Has zero or more `service_history` records.
- Has zero or more `service_schedule_override` records.

### Notes

`vehicle_specification_id` is optional. This permits an unlisted,
unusual or custom vehicle to be tracked without requiring catalogue data
first.

Because `vehicle_specification` is stored in the bundled SQLite
catalogue while `vehicle` is stored in SwiftData, this reference is not
implemented as a SwiftData relationship. The application resolves the
stored UUID against the catalogue database.

`name` is the user-facing name for the vehicle.

The `notes` field is intentionally free-form. A separate vehicle notes
table is not required for the initial design.

---

## service_item

### Purpose

Defines a type of maintenance operation.

Examples:

- Engine oil and filter
- Rear differential fluid
- Spark plugs
- Brake fluid
- Coolant
- Cabin air filter
- Engine air filter
- Tyre rotation
- Tyre replacement
- Automatic transmission fluid
- Front brake pads
- Rear brake pads

Service items are reusable across vehicle specifications and user
vehicles.

### Conceptual columns

```sql
service_item_id TEXT PRIMARY KEY NOT NULL
name            TEXT NOT NULL
description     TEXT
```

### Notes

A service item describes *what* was serviced. It does not contain the
interval, because intervals can differ between vehicle specifications.

Service item identifiers must remain stable between catalogue versions
because user-owned service history and schedule override records may
refer to them.

---

## service_schedule

### Purpose

Defines the default/recommended interval for a service item for a
particular vehicle specification.

This is catalogue/reference data and may be supplied with the
application.

### Conceptual columns

```sql
service_schedule_id      TEXT PRIMARY KEY NOT NULL
vehicle_specification_id TEXT NOT NULL
service_item_id          TEXT NOT NULL
interval_km              INTEGER
interval_months          INTEGER
notes                    TEXT
```

### Relationships

- Belongs to one `vehicle_specification`.
- Refers to one `service_item`.

Both related entities are part of the bundled SQLite catalogue, so
these relationships may be enforced using normal SQLite foreign keys.

There should be at most one default schedule for a given vehicle
specification and service item combination.

### Interval behaviour

Both distance and time intervals are supported.

For example:

```text
Engine oil and filter
15,000 km or 12 months
```

When both values are present, the application should normally regard the
service as due when either threshold is reached first.

A null interval means that dimension is not used.

Some service items, such as brake pad or tyre replacement, may have no
fixed interval and therefore need not have a `service_schedule` record.

---

## service_schedule_override

### Purpose

Allows the owner to use a different maintenance interval for one
particular vehicle without changing the generic catalogue schedule.

For example, the supplied specification may recommend an oil change
every 15,000 km while the owner prefers every 10,000 km.

### Conceptual columns

```sql
service_schedule_override_id TEXT PRIMARY KEY NOT NULL
vehicle_id                   TEXT NOT NULL
service_item_id              TEXT NOT NULL
interval_km                  INTEGER
interval_months              INTEGER
notes                        TEXT
```

### Relationships

- Belongs to one user-owned `vehicle`.
- Refers to one catalogue `service_item` by stable UUID.

The relationship to `vehicle` is represented using SwiftData.

The `service_item_id` reference crosses from the user's SwiftData store
to the bundled SQLite catalogue and is therefore represented as a
stable UUID rather than a SwiftData relationship.

There should be at most one override for a given vehicle and service
item combination.

### Effective schedule

Conceptually:

```text
effective schedule =
    vehicle-specific override, if one exists
    otherwise specification default
```

An override is user-owned data and should synchronise through iCloud.

---

## service_history

### Purpose

Records maintenance that was actually performed.

One row represents **one maintenance action**.

Service events are intentionally not grouped into workshop visits. If
oil, coolant and an air filter are changed on the same day, they are
three independent service history records.

### Conceptual columns

```sql
service_history_id TEXT PRIMARY KEY NOT NULL
vehicle_id         TEXT NOT NULL
service_item_id    TEXT NOT NULL
service_date       TEXT NOT NULL
odometer_km        INTEGER
performed_by       TEXT
cost               REAL
notes              TEXT
```

### Relationships

- Belongs to one user-owned `vehicle`.
- Refers to one catalogue `service_item` by stable UUID.

The relationship to `vehicle` is represented using SwiftData.

The `service_item_id` reference crosses from the user's SwiftData store
to the bundled SQLite catalogue and is therefore represented as a
stable UUID rather than a SwiftData relationship.

### performed_by

`performed_by` is deliberately a simple text value rather than a
separate entity.

Examples:

```text
Me
Honda dealer
Local mechanic
Bob Jane
```

The application is primarily intended for home servicing, so normalising
mechanics, workshops or suppliers is unnecessary for the initial design.

### Odometer

`odometer_km` may be null because historical maintenance records may
contain a date but no known odometer reading.

### Next due

The next-due odometer/date should not be persisted as authoritative
data.

It should be calculated from:

- the latest applicable service history record; and
- the effective service schedule.

For distance-based servicing:

```text
next due odometer =
    last service odometer + effective interval kilometres
```

For time-based servicing:

```text
next due date =
    last service date + effective interval months
```

This avoids derived values becoming inconsistent with history or
schedule changes.

---

## Catalogue data vs user data

The persistence architecture deliberately separates application-supplied
catalogue data from data belonging to the user.

### Catalogue / application-supplied data

```text
vehicle_specification
service_item
service_schedule
```

Catalogue data is stored in a SQLite database supplied with the
application.

The catalogue database is built before application distribution rather
than populated by importing large seed files on first launch. This
allows potentially large reference datasets, such as vehicle
specifications, to be immediately available and efficiently queried.

New versions of the application may supply updated versions of the
catalogue database.

Catalogue identifiers must remain stable between catalogue versions.

Catalogue data is not synchronised through CloudKit.

### Catalogue update compatibility

A newer application version may replace the bundled catalogue database,
but user-owned SwiftData records must remain resolvable across catalogue
updates.

The following compatibility rules apply:

- An existing conceptual catalogue record must retain the same UUID when
  its descriptive fields or schedule values are updated.
- A UUID must never be reused for a different conceptual record.
- New catalogue records receive new stable UUIDs.
- The catalogue schema version changes when application query code would
  need to interpret the database structure differently.
- The catalogue data version changes whenever catalogue content changes,
  even when the schema remains compatible.
- The application opens only catalogue schema versions it explicitly
  supports.
- User-owned UUID references are preserved even when the current
  catalogue cannot resolve them.

Vehicle specifications and service items that may already be referenced
by user data should not be deleted from later catalogue versions.
Instead, they should be retained as deprecated records, excluded from
new-selection lists but still available through UUID lookup.

Service schedules are not referenced directly by user-owned records and
may be replaced or removed, provided the stable UUIDs of their vehicle
specifications and service items remain resolvable.

### User-owned data

```text
vehicle
service_history
service_schedule_override
```

User-owned data is persisted using SwiftData and should synchronise
through CloudKit/iCloud.

User-owned records refer to catalogue records using stable UUID
identifiers rather than SwiftData relationships. This avoids creating
persistence relationships between the bundled catalogue database and
the user's synchronised SwiftData store.

For example:

```text
vehicle.vehicle_specification_id
    -> vehicle_specification.vehicle_specification_id

service_history.service_item_id
    -> service_item.service_item_id

service_schedule_override.service_item_id
    -> service_item.service_item_id
```

These references are resolved by application code and are not
foreign-key relationships enforced across the two persistence stores.

Relationships entirely within user-owned data, such as a service
history record belonging to a vehicle, are represented using SwiftData
relationships.

---

## Seed data and example data

Database scripts should distinguish between reference seed data and
development/test user data.

### seed.sql

Contains catalogue/reference data used to build the SQLite catalogue
that may ship with the application:

- vehicle specifications
- service items
- recommended service schedules

Large source datasets may also be imported as part of the catalogue
build process.

Seed/import processing occurs during development or application build
preparation, not when an end user first launches the application.

### example-data.sql

Contains representative user data for development and testing:

- example owned vehicles
- service history
- schedule overrides

Example data must not be treated as application catalogue data.

---

## Identifiers

The conceptual SQL schema stores identifiers as `TEXT` UUID values
rather than sequential integer primary keys.

Example:

```text
a3d6bb98-7df7-4e65-bbc7-ff94192b8144
```

UUIDs have two roles in IVDB.

For user-owned SwiftData records, UUIDs allow records to be created
independently on multiple devices while offline and later synchronised.

For catalogue records, UUIDs provide stable identifiers that can be
stored by user-owned records and resolved against later versions of the
catalogue.

Catalogue UUIDs must therefore remain stable when the catalogue
database is rebuilt or updated.

In Swift, identifiers should use `UUID`, for example:

```swift
var id: UUID = UUID()
```

The SQLite catalogue may store UUID values as text while SwiftData
handles the persistence representation of user-owned UUIDs.

---

## SQL and Swift naming

The SQL documentation uses conventional database naming:

```text
vehicle_specification
service_history
service_date
odometer_km
performed_by
```

Swift code should use normal Swift naming conventions:

```text
VehicleSpecification
ServiceHistory
serviceDate
odometerKm
performedBy
```

Types use `UpperCamelCase`; properties and functions use
`lowerCamelCase`.

---

## Application persistence mapping

The six conceptual entities are divided between two persistence
mechanisms.

### SQLite catalogue

```text
VehicleSpecification
ServiceItem
ServiceSchedule
```

These entities are application-supplied reference data stored in the
bundled SQLite catalogue.

Relationships between catalogue entities are represented using normal
SQLite foreign keys.

The catalogue is primarily read-only at application runtime. Updated
catalogue data is supplied by newer versions of the application rather
than synchronised as user data.

### SwiftData user data

```text
Vehicle
ServiceScheduleOverride
ServiceHistory
```

These entities contain user-owned data and are persisted using
SwiftData.

Relationships between user-owned entities should use SwiftData
relationships where appropriate.

References from SwiftData user data to SQLite catalogue data use stable
UUID identifiers. For example, a `Vehicle` stores an optional
`vehicleSpecificationId` rather than a SwiftData relationship to a
`VehicleSpecification`.

The application is responsible for resolving these identifiers against
the catalogue database.

---

### Development migration policy

The original six-model SwiftData schema was a development prototype and
has not been distributed with production user data.

Existing development `Vehicle` records may be retained when the schema
changes permit automatic migration. Catalogue SwiftData records from the
prototype are disposable because catalogue data will be rebuilt from the
application-supplied SQLite database.

Prototype `ServiceHistory` and `ServiceScheduleOverride` relationships
to SwiftData `ServiceItem` records cannot be converted automatically
into stable catalogue UUID references without an explicit mapping. No
such records were created by the prototype application. If an
incompatible development store is encountered, the application may be
deleted from the Simulator to reset its local development data.

Before distributing builds containing real user data, SwiftData schema
changes must use an explicit versioning and migration strategy that
preserves user-owned records.

---

## CloudKit / iCloud considerations

User data is intended to work locally/offline and synchronise between
the user's Apple devices through CloudKit/iCloud.

The design therefore assumes:

- records may be created independently on different devices;
- UUID identifiers are preferable to locally generated sequential IDs;
- the application should not depend on a permanently available network
  connection;
- only user-owned SwiftData models are synchronised through CloudKit;
- the bundled SQLite catalogue is not part of the CloudKit store;
- catalogue/reference data and personal synchronised data are
  deliberately separated;
- cross-store references use stable catalogue UUIDs rather than
  SwiftData relationships;
- SwiftData relationships used by synchronised models must be designed
  for CloudKit compatibility;
- model changes should consider SwiftData/CloudKit compatibility from
  the beginning.

---

## Scope deliberately excluded from the initial model

The initial model does **not** include:

- workshop/service visits containing multiple maintenance actions;
- a mechanics/workshops table;
- a separate vehicle notes table;
- receipts or document attachments;
- parts inventory;
- fuel tracking;
- tyre inventory/position tracking;
- manufacturer/dealer entities;
- persisted calculated next-due values.

These can be added later if an actual requirement emerges. The initial
goal is a small model for recording individual vehicle maintenance
events and determining when scheduled maintenance is next due.