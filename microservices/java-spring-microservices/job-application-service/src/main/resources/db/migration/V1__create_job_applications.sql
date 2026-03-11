-- Flyway migration: create job_applications and application_status_history tables
CREATE TABLE IF NOT EXISTS job_applications (
    applicant_id UUID PRIMARY KEY,
    role_type VARCHAR(50) NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(200),
    dob TIMESTAMP WITH TIME ZONE,
    location_text TEXT,
    highest_qualification VARCHAR(100),
    institution VARCHAR(255),
    year_of_completion INT,
    years_experience INT,
    relevant_experience TEXT,
    last_employer_role VARCHAR(255),
    vehicle_available BOOLEAN,
    willing_for_field_visit BOOLEAN,
    resume_url TEXT,
    current_status VARCHAR(50) NOT NULL DEFAULT 'SCREENING',
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by UUID,
    updated_by UUID
);

CREATE TABLE IF NOT EXISTS application_status_history (
    id UUID PRIMARY KEY,
    applicant_id UUID REFERENCES job_applications(applicant_id),
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_by UUID,
    comment TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
