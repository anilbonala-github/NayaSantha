-- Configurable ops settings (Vol2A §9 pricing knobs + §2 fulfilment). Single row.
CREATE TABLE ops_settings (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buffer_percent              INT NOT NULL DEFAULT 5,          -- procurement buffer (FR-007)
    cap_percent                 NUMERIC(5,2) NOT NULL DEFAULT 2.5, -- guaranteed-max markup over estimate
    variance_threshold_percent  INT NOT NULL DEFAULT 10,         -- material price-change alert
    delivery_slot               VARCHAR(60) NOT NULL DEFAULT 'Sun 2:00-8:00 PM',
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    version                     BIGINT NOT NULL DEFAULT 0
);

INSERT INTO ops_settings (buffer_percent, cap_percent, variance_threshold_percent, delivery_slot)
VALUES (5, 2.5, 10, 'Sun 2:00-8:00 PM');
