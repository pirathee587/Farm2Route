-- V19__enhance_review_tables.sql
-- Enhance reviews table with distinct agency_comment and driver_comment columns

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS agency_comment TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS driver_comment TEXT;
