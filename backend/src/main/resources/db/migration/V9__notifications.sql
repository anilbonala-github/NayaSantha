-- In-app notifications (Vol2 §3.2, Vol2A §13). Created by the order/settlement
-- lifecycle; FCM push can later mirror these rows.
CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       VARCHAR(40) NOT NULL,
    title      VARCHAR(160) NOT NULL,
    body       VARCHAR(500) NOT NULL,
    order_id   UUID,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
