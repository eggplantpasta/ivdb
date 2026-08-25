# IVDB Data Model

## Purpose

IVDB is a simple vehicle service tracking application for Apple
platforms.

The application is primarily intended to record individual maintenance
events for vehicles owned by the user. The design also supports shipping
a catalogue of vehicle specifications and recommended service schedules
with the application.

The SQL schema in `docs/database/` is the **conceptual relational model
and design reference**. The application persistence layer will be
implemented using SwiftData, with user data intended to synchronise
between the user's devices using CloudKit/iCloud.

The model is deliberately kept small and conventional.

## Design principles

-   Keep the model simple.
-   One service history record represents one maintenance action;
    service actions are not grouped into workshop visits.
-   Separate generic vehicle/model information from an individual user's
    vehicle.
-   Separate application-supplied catalogue data from user-owned data.
-   Allow a vehicle to exist even when its model is not present in the
    supplied vehicle catalogue.
-   Recommended schedules belong to a vehicle specification.
-   Users may override the recommended schedule for an individual
    vehicle.
-   Do not store calculated "next due" values when they can be derived
    from service history and schedule data.
-   Use UUIDs for persistent identifiers so records can be safely
    created independently on multiple devices.
-   The SQL design is a reference model; Swift code should use normal
    Swift naming and SwiftData relationships rather than attempting to
    reproduce SQL mechanically.

## Entities

The model contains six entities:

1.  `vehicle_specification`
2.  `vehicle`
3.  `service_item`
4.  `service_schedule`
5.  `service_schedule_override`
6.  `service_history`

## Relationships

``` text
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

------------------------------------------------------------------------

## vehicle_specification

### Purpose

Represents a generic vehicle model/variant rather than an individual
physical vehicle.

Examples include a particular generation, series, engine and
transmission combination of a Honda CR-V.

Vehicle specifications are catalogue/reference data and may be supplied
with the application.

### Conceptual columns

``` sql
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

------------------------------------------------------------------------

## vehicle

### Purpose

Represents an actual vehicle owned or maintained by the user.

This is user-owned data and is expected to synchronise through iCloud.

### Conceptual columns

``` sql
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

-   Optionally belongs to one `vehicle_specification`.
-   Has zero or more `service_history` records.
-   Has zero or more `service_schedule_override` records.

### Notes

`vehicle_specification_id` is optional. This permits an unlisted,
unusual or custom vehicle to be tracked without requiring catalogue data
first.

`name` is the user-facing name for the vehicle.

The `notes` field is intentionally free-form. A separate vehicle notes
table is not required for the initial design.

------------------------------------------------------------------------

## service_item

### Purpose

Defines a type of maintenance operation.

Examples:

-   Engine oil and filter
-   Rear differential fluid
-   Spark plugs
-   Brake fluid
-   Coolant
-   Cabin air filter
-   Engine air filter
-   Tyre rotation
-   Tyre replacement
-   Automatic transmission fluid
-   Front brake pads
-   Rear brake pads

Service items are reusable across vehicle specifications and user
vehicles.

### Conceptual columns

``` sql
service_item_id TEXT PRIMARY KEY NOT NULL
name            TEXT NOT NULL
description     TEXT
```

### Notes

A service item describes *what* was serviced. It does not contain the
interval, because intervals can differ between vehicle specifications.

------------------------------------------------------------------------

## service_schedule

### Purpose

Defines the default/recommended interval for a service item for a
particular vehicle specification.

This is catalogue/reference data and may be supplied with the
application.

### Conceptual columns

``` sql
service_schedule_id      TEXT PRIMARY KEY NOT NULL
vehicle_specification_id TEXT NOT NULL
service_item_id          TEXT NOT NULL
interval_km              INTEGER
interval_months          INTEGER
notes                    TEXT
```

### Relationships

-   Belongs to one `vehicle_specification`.
-   Refers to one `service_item`.

There should be at most one default schedule for a given vehicle
specification and service item combination.

### Interval behaviour

Both distance and time intervals are supported.

For example:

``` text
Engine oil and filter
15,000 km or 12 months
```

When both values are present, the application should normally regard the
service as due when either threshold is reached first.

A null interval means that dimension is not used.

Some service items, such as brake pad or tyre replacement, may have no
fixed interval and therefore need not have a `service_schedule` record.

------------------------------------------------------------------------

## service_schedule_override

### Purpose

Allows the owner to use a different maintenance interval for one
particular vehicle without changing the generic catalogue schedule.

For example, the supplied specification may recommend an oil change
every 15,000 km while the owner prefers every 10,000 km.

### Conceptual columns

``` sql
service_schedule_override_id TEXT PRIMARY KEY NOT NULL
vehicle_id                   TEXT NOT NULL
service_item_id              TEXT NOT NULL
interval_km                  INTEGER
interval_months              INTEGER
notes                        TEXT
```

### Relationships

-   Belongs to one `vehicle`.
-   Refers to one `service_item`.

There should be at most one override for a given vehicle and service
item combination.

### Effective schedule

Conceptually:

``` text
effective schedule =
    vehicle-specific override, if one exists
    otherwise specification default
```

An override is user-owned data and should synchronise through iCloud.

------------------------------------------------------------------------

## service_history

### Purpose

Records maintenance that was actually performed.

One row represents **one maintenance action**.

Service events are intentionally not grouped into workshop visits. If
oil, coolant and an air filter are changed on the same day, they are
three independent service history records.

### Conceptual columns

``` sql
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

-   Belongs to one `vehicle`.
-   Refers to one `service_item`.

### performed_by

`performed_by` is deliberately a simple text value rather than a
separate entity.

Examples:

``` text
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

-   the latest applicable service history record; and
-   the effective service schedule.

For distance-based servicing:

``` text
next due odometer =
    last service odometer + effective interval kilometres
```

For time-based servicing:

``` text
next due date =
    last service date + effective interval months
```

This avoids derived values becoming inconsistent with history or
schedule changes.

------------------------------------------------------------------------

## Catalogue data vs user data

The model deliberately separates data that may ship with IVDB from data
belonging to the user.

### Catalogue / application-supplied data

``` text
vehicle_specification
service_item
service_schedule
```

This data can be seeded by the application and updated as the supplied
vehicle catalogue evolves.

It should not need to be copied into every user's iCloud data simply to
make the catalogue available.

### User-owned data

``` text
vehicle
service_history
service_schedule_override
```

This data belongs to the user and should be persisted locally and
synchronised through CloudKit/iCloud.

------------------------------------------------------------------------

## Seed data and example data

Database scripts should distinguish between reference seed data and
development/test user data.

### seed.sql

Contains catalogue/reference data that could eventually ship with the
application:

-   vehicle specifications
-   service items
-   recommended service schedules

### example-data.sql

Contains representative user data for development and testing:

-   example owned vehicles
-   service history
-   schedule overrides

Example data must not be treated as application catalogue data.

------------------------------------------------------------------------

## Identifiers

The conceptual SQL schema stores identifiers as `TEXT` UUID values
rather than sequential integer primary keys.

Example:

``` text
a3d6bb98-7df7-4e65-bbc7-ff94192b8144
```

This is suitable for data that may be created independently on multiple
devices while offline and later synchronised.

In Swift, identifiers should use `UUID`, for example:

``` swift
var id: UUID = UUID()
```

The exact persistence representation is the responsibility of SwiftData.

------------------------------------------------------------------------

## SQL and Swift naming

The SQL documentation uses conventional database naming:

``` text
vehicle_specification
service_history
service_date
odometer_km
performed_by
```

Swift code should use normal Swift naming conventions:

``` text
VehicleSpecification
ServiceHistory
serviceDate
odometerKm
performedBy
```

Types use `UpperCamelCase`; properties and functions use
`lowerCamelCase`.

------------------------------------------------------------------------

## SwiftData mapping

The SQL files are a conceptual design reference rather than a
requirement to create or manipulate SQLite tables directly from the
application.

Expected conceptual SwiftData models are:

``` text
VehicleSpecification
Vehicle
ServiceItem
ServiceSchedule
ServiceScheduleOverride
ServiceHistory
```

Relationships should be represented as SwiftData model relationships
rather than manually managed foreign-key strings where appropriate.

The SwiftData implementation should preserve the semantics described in
this document while following normal Swift/SwiftData idioms.

------------------------------------------------------------------------

## CloudKit / iCloud considerations

User data is intended to work locally/offline and synchronise between
the user's Apple devices through CloudKit/iCloud.

The design therefore assumes:

-   records may be created independently on different devices;
-   UUID identifiers are preferable to locally generated sequential IDs;
-   the application should not depend on a permanently available network
    connection;
-   catalogue/reference data and personal synchronised data are
    conceptually distinct;
-   model changes should consider SwiftData/CloudKit compatibility from
    the beginning.

------------------------------------------------------------------------

## Scope deliberately excluded from the initial model

The initial model does **not** include:

-   workshop/service visits containing multiple maintenance actions;
-   a mechanics/workshops table;
-   a separate vehicle notes table;
-   receipts or document attachments;
-   parts inventory;
-   fuel tracking;
-   tyre inventory/position tracking;
-   manufacturer/dealer entities;
-   persisted calculated next-due values.

These can be added later if an actual requirement emerges. The initial
goal is a small model for recording individual vehicle maintenance
events and determining when scheduled maintenance is next due.
