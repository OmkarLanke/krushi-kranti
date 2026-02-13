-- Flyway migration: add HR interview and offer letter columns
ALTER TABLE job_applications
    ADD COLUMN IF NOT EXISTS hr_interview_date DATE,
    ADD COLUMN IF NOT EXISTS hr_interview_time TIME,
    ADD COLUMN IF NOT EXISTS hr_interview_venue VARCHAR(500),
    ADD COLUMN IF NOT EXISTS hr_required_documents TEXT,
    ADD COLUMN IF NOT EXISTS offer_letter_url TEXT,
    ADD COLUMN IF NOT EXISTS offer_sent_at TIMESTAMP WITH TIME ZONE;

-- Add comment for documentation
COMMENT ON COLUMN job_applications.hr_interview_date IS 'Date of scheduled HR interview';
COMMENT ON COLUMN job_applications.hr_interview_time IS 'Time of scheduled HR interview';
COMMENT ON COLUMN job_applications.hr_interview_venue IS 'Venue/location for HR interview';
COMMENT ON COLUMN job_applications.hr_required_documents IS 'JSON array of required documents for interview';
COMMENT ON COLUMN job_applications.offer_letter_url IS 'URL to the uploaded offer letter PDF';
COMMENT ON COLUMN job_applications.offer_sent_at IS 'Timestamp when offer letter was sent';
