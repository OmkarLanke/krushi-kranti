-- V3__add_performance_indexes.sql
-- Performance indexes for faster queries on frequently accessed columns

-- Job Applications table indexes
CREATE INDEX IF NOT EXISTS idx_job_applications_role_type ON job_applications(role_type);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(current_status);
CREATE INDEX IF NOT EXISTS idx_job_applications_email ON job_applications(email);
CREATE INDEX IF NOT EXISTS idx_job_applications_mobile ON job_applications(mobile);
CREATE INDEX IF NOT EXISTS idx_job_applications_submitted_at ON job_applications(submitted_at DESC);

-- Composite indexes for common admin queries
CREATE INDEX IF NOT EXISTS idx_job_applications_status_role ON job_applications(current_status, role_type);
CREATE INDEX IF NOT EXISTS idx_job_applications_status_submitted ON job_applications(current_status, submitted_at DESC);

-- Application Status History indexes
CREATE INDEX IF NOT EXISTS idx_status_history_applicant_id ON application_status_history(applicant_id);
CREATE INDEX IF NOT EXISTS idx_status_history_changed_at ON application_status_history(changed_at DESC);
