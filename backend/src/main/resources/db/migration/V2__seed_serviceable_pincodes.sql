-- Operational config for the Hyderabad apartment-first pilot (Vol1 §7, §18).
-- These are real serviceability records, not demo business data.
INSERT INTO serviceable_pincodes (pincode, area_name, active) VALUES
    ('500081', 'Gachibowli',        true),
    ('500084', 'Kondapur',          true),
    ('500032', 'Financial District', true),
    ('500089', 'Narsingi',          true),
    ('500019', 'Miyapur',           true)
ON CONFLICT (pincode) DO NOTHING;
