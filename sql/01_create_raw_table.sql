-- Raw support ticket export, exactly as it arrived: every column TEXT,
-- no constraints, no cleanup. The mess is preserved on purpose.
DROP TABLE IF EXISTS tickets_raw;
CREATE TABLE tickets_raw (
    ticket_ref      TEXT,
    requester_email TEXT,
    category        TEXT,
    priority        TEXT,
    status          TEXT,
    created_at      TEXT,
    resolved_at     TEXT,
    subject         TEXT
);
-- Load data/tickets_raw.csv into tickets_raw (see scripts/build.py).
