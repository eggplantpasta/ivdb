PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================
-- Catalogue metadata
-- ============================================================

INSERT INTO catalogue_metadata (
    metadata_id,
    schema_version,
    data_version
)
VALUES (
    1,
    2,
    2
);

-- ============================================================
-- Vehicle specifications
-- ============================================================

INSERT INTO vehicle_specification (
    vehicle_specification_id,
    make,
    model,
    generation,
    year_from,
    year_to,
    series,
    trim,
    body_type,
    engine,
    transmission
)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Honda',
    'CR-V',
    'Third generation',
    2007,
    2012,
    'RE4',
    NULL,
    'SUV',
    'K24Z1 2.4L I4 DOHC VTEC',
    'Automatic'
);


-- ============================================================
-- Service items
-- ============================================================

INSERT INTO service_item (
    service_item_id,
    name,
    description
)
VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'Engine oil and filter',
    'Replace engine oil and oil filter'
),
(
    'b0000000-0000-0000-0000-000000000002',
    'Rear differential fluid',
    'Replace rear differential fluid on AWD models'
),
(
    'b0000000-0000-0000-0000-000000000003',
    'Spark plugs',
    'Replace spark plugs'
),
(
    'b0000000-0000-0000-0000-000000000004',
    'Brake fluid',
    'Replace brake fluid'
),
(
    'b0000000-0000-0000-0000-000000000005',
    'Engine coolant',
    'Replace engine coolant'
),
(
    'b0000000-0000-0000-0000-000000000006',
    'Cabin air filter',
    'Replace cabin air / pollen filter'
),
(
    'b0000000-0000-0000-0000-000000000007',
    'Engine air filter',
    'Replace engine air cleaner element'
),
(
    'b0000000-0000-0000-0000-000000000008',
    'Tyre rotation',
    'Rotate tyres'
),
(
    'b0000000-0000-0000-0000-000000000009',
    'Tyre replacement',
    'Replace tyres as required'
),
(
    'b0000000-0000-0000-0000-000000000010',
    'Automatic transmission fluid',
    'Replace automatic transmission fluid'
),
(
    'b0000000-0000-0000-0000-000000000011',
    'Front brake pads',
    'Replace front brake pads as required'
),
(
    'b0000000-0000-0000-0000-000000000012',
    'Rear brake pads',
    'Replace rear brake pads as required'
),
(
    'b0000000-0000-0000-0000-000000000013',
    'Brake inspection',
    'Inspect front and rear brakes'
),
(
    'b0000000-0000-0000-0000-000000000014',
    'Drive belt inspection',
    'Inspect accessory drive belt condition'
),
(
    'b0000000-0000-0000-0000-000000000015',
    'Valve clearance inspection',
    'Inspect valve clearances and adjust if required'
);


-- ============================================================
-- Honda CR-V example service schedule
--
-- Representative schedule for a third-generation petrol AWD
-- Honda CR-V. Intended as realistic development/catalogue data,
-- not an authoritative manufacturer service schedule.
--
-- Where both distance and time are specified, service is due
-- when either threshold is reached first.
-- ============================================================

INSERT INTO service_schedule (
    service_schedule_id,
    vehicle_specification_id,
    service_item_id,
    interval_km,
    interval_months,
    notes
)
VALUES
(
    'c0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    10000,
    12,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000002',
    40000,
    24,
    'Representative AWD rear differential fluid interval'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000003',
    100000,
    NULL,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000004',
    NULL,
    36,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000005',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000005',
    100000,
    60,
    'Repeating replacement interval; initial factory coolant interval may be longer'
),
(
    'c0000000-0000-0000-0000-000000000006',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000006',
    30000,
    12,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000007',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000007',
    20000,
    NULL,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000008',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000008',
    10000,
    NULL,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000009',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000010',
    60000,
    36,
    'Representative automatic transmission fluid interval'
),
(
    'c0000000-0000-0000-0000-000000000010',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000013',
    10000,
    12,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000011',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000014',
    40000,
    24,
    NULL
),
(
    'c0000000-0000-0000-0000-000000000012',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000015',
    100000,
    NULL,
    'Inspect and adjust valve clearance if required'
);

COMMIT;