-- V17__seed_packages_and_indexes.sql
-- Indexes for optimized farmer package search & catalog discovery

CREATE INDEX IF NOT EXISTS idx_packages_route ON packages(route_origin, route_destination);
CREATE INDEX IF NOT EXISTS idx_packages_price ON packages(base_price);
CREATE INDEX IF NOT EXISTS idx_packages_weight ON packages(max_weight_kg);

-- Safely ensure demo agency user exists (idempotent, safe on both fresh and seeded DBs)
INSERT INTO users (id, email, phone_number, password_hash, role, status, phone_verified)
VALUES 
    ('00000000-0000-0000-0000-000000000002', 'info@greenroute.lk', '+94770000002', '$2a$12$Vn9q7Z6d4G5f2w1y0X8t.OXW0jK3P9vY2rL4nM1k5P7j8R9a6E5r6', 'AGENCY', 'ACTIVE', true)
ON CONFLICT (phone_number) DO NOTHING;

-- Safely ensure demo agency profile exists
INSERT INTO agency_profiles (id, user_id, company_name, business_registration_number, tax_identification_number, office_address, district, contact_person_name, contact_person_phone, kyc_status, commission_rate_percentage)
VALUES 
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Green Route Logistics Ltd', 'PV-109283', 'TIN-987654321', '120 Kandy Road, Kurunegala', 'Kurunegala', 'Sunil Perera', '+94770000002', 'APPROVED', 10.00)
ON CONFLICT (business_registration_number) DO NOTHING;

-- Seed Sample Transport Packages for Farmer Discovery with collision safeguards
INSERT INTO packages (
    id, agency_id, title, description, package_type, base_price, price_per_km, price_per_kg, max_weight_kg, route_origin, route_destination, schedule_days, is_active
) VALUES 
    (
        '40000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        'Kurunegala to Colombo Agro Express',
        'Direct overnight fresh vegetable transit connecting Wayamba growers with Pettah wholesale market.',
        'STANDARD',
        5000.00,
        120.00,
        15.00,
        3500.00,
        'Kurunegala',
        'Colombo',
        ARRAY['MONDAY', 'WEDNESDAY', 'FRIDAY'],
        true
    ),
    (
        '40000000-0000-0000-0000-000000000002',
        '10000000-0000-0000-0000-000000000001',
        'Dambulla Cold Chain Vegetable Transit',
        'Temperature controlled transport (4°C - 8°C) for perishable fruits and exotic vegetables.',
        'COLD_CHAIN',
        8500.00,
        160.00,
        25.00,
        5000.00,
        'Dambulla',
        'Colombo',
        ARRAY['DAILY'],
        true
    ),
    (
        '40000000-0000-0000-0000-000000000003',
        '10000000-0000-0000-0000-000000000001',
        'Anuradhapura Paddy & Bulk Haulage',
        'Heavy tonnage open-bed transport for grains, paddy sacks, and harvest produce.',
        'BULK_AGRICULTURAL',
        12000.00,
        140.00,
        10.00,
        10000.00,
        'Anuradhapura',
        'Dambulla',
        ARRAY['TUESDAY', 'THURSDAY', 'SATURDAY'],
        true
    ),
    (
        '40000000-0000-0000-0000-000000000004',
        '10000000-0000-0000-0000-000000000001',
        'Islandwide Fresh Produce Fast Track',
        'Priority high-speed direct transport for urgent deliveries to supermarket distribution centers.',
        'EXPRESS',
        7000.00,
        150.00,
        20.00,
        2000.00,
        'Kandy',
        'Colombo',
        ARRAY['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'],
        true
    )
ON CONFLICT (id) DO NOTHING;
