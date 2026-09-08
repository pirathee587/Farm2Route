-- V23__add_driver_full_name.sql
-- Add full_name to driver_profiles table
-- Drivers' names are domain data belonging to the driver profile,
-- not the shared users identity table (which stores only auth credentials).

ALTER TABLE driver_profiles
    ADD COLUMN IF NOT EXISTS full_name VARCHAR(150);
