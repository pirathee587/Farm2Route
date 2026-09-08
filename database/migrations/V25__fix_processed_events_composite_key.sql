-- V25__fix_processed_events_composite_key.sql
-- Alter processed_events table to support per-consumer idempotency tracking.
-- Drops single-column PK (event_id) and establishes composite PK on (event_id, consumer_name).

ALTER TABLE processed_events
    DROP CONSTRAINT IF EXISTS processed_events_pkey;

ALTER TABLE processed_events
    ADD COLUMN IF NOT EXISTS consumer_name VARCHAR(100) NOT NULL DEFAULT 'legacy';

ALTER TABLE processed_events
    ADD CONSTRAINT processed_events_pkey PRIMARY KEY (event_id, consumer_name);
