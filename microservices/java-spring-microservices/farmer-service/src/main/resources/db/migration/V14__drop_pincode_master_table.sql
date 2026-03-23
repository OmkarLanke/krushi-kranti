-- Drop pincode_master table: address lookup now uses data.gov.in API
DROP INDEX IF EXISTS idx_pincode_master_pincode;
DROP INDEX IF EXISTS idx_pincode_master_state;
DROP INDEX IF EXISTS idx_pincode_master_district;
DROP INDEX IF EXISTS idx_pincode_master_unique;
DROP TABLE IF EXISTS pincode_master;
