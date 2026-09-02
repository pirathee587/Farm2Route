-- Farm2Route Initial Seed Data for Development
-- Encrypted password is 'Password123!' (BCrypt strength 12)
-- Hash: $2a$12$Nq/t4gB4qK25c5gUu.V9n.PqZqN4g5y6eE9xJt7h8i9j0k1l2m3n4 (or dynamic generated)

-- Seed Admin User
INSERT INTO users (id, email, phone_number, password_hash, full_name, role, status, is_phone_verified, is_email_verified)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'admin@farm2route.com', '+94770000001', '$2a$12$Vn9q7Z6d4G5f2w1y0X8t.OXW0jK3P9vY2rL4nM1k5P7j8R9a6E5r6', 'Super Admin', 'ADMIN', 'ACTIVE', true, true)
ON CONFLICT (phone_number) DO NOTHING;

-- Seed Sample Logistics Agency
INSERT INTO users (id, email, phone_number, password_hash, full_name, role, status, is_phone_verified, is_email_verified)
VALUES 
    ('00000000-0000-0000-0000-000000000002', 'info@greenroute.lk', '+94770000002', '$2a$12$Vn9q7Z6d4G5f2w1y0X8t.OXW0jK3P9vY2rL4nM1k5P7j8R9a6E5r6', 'Green Route Logistics', 'AGENCY', 'ACTIVE', true, true)
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO agency_profiles (id, user_id, company_name, business_registration_number, tax_identification_number, office_address, district, contact_person_name, contact_person_phone, kyc_status, commission_rate_percentage)
VALUES 
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Green Route Logistics Ltd', 'PV-109283', 'TIN-987654321', '120 Kandy Road, Kurunegala', 'Kurunegala', 'Sunil Perera', '+94770000002', 'APPROVED', 10.00)
ON CONFLICT (business_registration_number) DO NOTHING;

-- Seed Sample Driver
INSERT INTO users (id, email, phone_number, password_hash, full_name, role, status, is_phone_verified, is_email_verified)
VALUES 
    ('00000000-0000-0000-0000-000000000003', 'kamal.driver@farm2route.com', '+94770000003', '$2a$12$Vn9q7Z6d4G5f2w1y0X8t.OXW0jK3P9vY2rL4nM1k5P7j8R9a6E5r6', 'Kamal Silva', 'DRIVER', 'ACTIVE', true, true)
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO driver_profiles (id, user_id, agency_id, driving_license_number, license_expiry_date, nic_number, kyc_status, availability_status)
VALUES 
    ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'B8493821', '2028-12-31', '199012345678', 'APPROVED', 'AVAILABLE')
ON CONFLICT (driving_license_number) DO NOTHING;

-- Seed Sample Farmer
INSERT INTO users (id, email, phone_number, password_hash, full_name, role, status, is_phone_verified, is_email_verified)
VALUES 
    ('00000000-0000-0000-0000-000000000004', 'nimal.farmer@gmail.com', '+94770000004', '$2a$12$Vn9q7Z6d4G5f2w1y0X8t.OXW0jK3P9vY2rL4nM1k5P7j8R9a6E5r6', 'Nimal Bandara', 'FARMER', 'ACTIVE', true, true)
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO farmer_profiles (id, user_id, farm_name, address, district, province, latitude, longitude, farm_size_hectares, primary_crops)
VALUES 
    ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', 'Bandara Organic Greens', 'Galgamuwa Farm Road', 'Anuradhapura', 'North Central', 8.012345, 80.293847, 4.5, ARRAY['Paddy', 'Vegetables', 'Chili'])
ON CONFLICT (user_id) DO NOTHING;
