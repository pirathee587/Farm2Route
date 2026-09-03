-- Idempotency table for RabbitMQ event consumers.
-- Each consumer inserts event_id before processing.
-- The PRIMARY KEY uniqueness constraint is the idempotency guard (INSERT-first pattern).
-- If two consumers race on the same event, the second INSERT fails with a duplicate key
-- violation, which IdempotentConsumerHelper catches and uses to skip duplicate processing.
CREATE TABLE IF NOT EXISTS processed_events (
    event_id    UUID        PRIMARY KEY,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE processed_events IS
    'Tracks RabbitMQ events that have been successfully processed to prevent duplicate side effects (at-least-once delivery idempotency guard).';
