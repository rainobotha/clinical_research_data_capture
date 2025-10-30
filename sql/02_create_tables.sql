-- ============================================================================
-- Clinical Research Data Capture - Core Tables
-- ============================================================================
-- Creates tables for managing clinical research data
-- Replaces spreadsheet-based data collection
--
-- Execute as: ACCOUNTADMIN or RESEARCH_ADMIN role
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RESEARCH_WH;
USE DATABASE CLINICAL_RESEARCH;
USE SCHEMA RESEARCH_DATA;

-- ============================================================================
-- Studies and Protocols
-- ============================================================================

CREATE OR REPLACE TABLE STUDIES (
    study_id VARCHAR(50) PRIMARY KEY,
    study_name VARCHAR(500) NOT NULL,
    study_number VARCHAR(100) UNIQUE,  -- IRB number or protocol number
    principal_investigator VARCHAR(255) NOT NULL,
    study_phase VARCHAR(50),  -- Planning, Active, Analysis, Complete
    study_type VARCHAR(100),  -- Clinical Trial, Observational, Chart Review, etc.
    study_description TEXT,
    irb_approval_number VARCHAR(100),
    irb_approval_date DATE,
    study_start_date DATE,
    study_end_date DATE,
    target_enrollment INTEGER,
    current_enrollment INTEGER DEFAULT 0,
    study_status VARCHAR(50) DEFAULT 'ACTIVE',
    study_sponsor VARCHAR(255),
    study_site VARCHAR(255),
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_by VARCHAR(255),
    modified_date TIMESTAMP_NTZ,
    metadata VARIANT  -- Flexible JSON for study-specific fields
);

-- ============================================================================
-- Study Participants
-- ============================================================================

CREATE OR REPLACE TABLE PARTICIPANTS (
    participant_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_number VARCHAR(100),  -- Study-specific ID (not PHI)
    enrollment_date DATE,
    consent_date DATE,
    consent_version VARCHAR(50),
    demographic_group VARCHAR(100),  -- Age group, gender (de-identified)
    inclusion_criteria_met BOOLEAN DEFAULT TRUE,
    exclusion_criteria_met BOOLEAN DEFAULT FALSE,
    randomization_arm VARCHAR(100),  -- For randomized trials
    participant_status VARCHAR(50) DEFAULT 'ACTIVE',  -- Active, Completed, Withdrawn
    withdrawal_date DATE,
    withdrawal_reason TEXT,
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_by VARCHAR(255),
    modified_date TIMESTAMP_NTZ,
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id)
);

-- ============================================================================
-- Clinical Observations
-- ============================================================================

CREATE OR REPLACE TABLE OBSERVATIONS (
    observation_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_id VARCHAR(50) NOT NULL,
    observation_date DATE NOT NULL,
    observation_time TIME,
    visit_number INTEGER,
    visit_name VARCHAR(100),  -- Baseline, Week 4, Month 6, etc.
    observation_type VARCHAR(100),  -- Vital Signs, Lab Result, Assessment, etc.
    observation_category VARCHAR(100),  -- Efficacy, Safety, Quality of Life
    measurement_name VARCHAR(255),
    measurement_value VARCHAR(500),
    measurement_unit VARCHAR(50),
    normal_range VARCHAR(100),
    clinically_significant BOOLEAN,
    data_quality_score INTEGER,  -- 0-100
    data_verified BOOLEAN DEFAULT FALSE,
    verified_by VARCHAR(255),
    verified_date TIMESTAMP_NTZ,
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_by VARCHAR(255),
    modified_date TIMESTAMP_NTZ,
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id),
    FOREIGN KEY (participant_id) REFERENCES PARTICIPANTS(participant_id)
);

-- ============================================================================
-- Research Notes and Findings
-- ============================================================================

CREATE OR REPLACE TABLE RESEARCH_NOTES (
    note_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_id VARCHAR(50),  -- NULL for study-level notes
    observation_id VARCHAR(50),  -- NULL for general notes
    note_type VARCHAR(100),  -- Progress Note, Adverse Event, Protocol Deviation, Finding
    note_category VARCHAR(100),  -- Clinical, Administrative, Safety, Quality
    note_title VARCHAR(500),
    note_text TEXT NOT NULL,
    note_date DATE DEFAULT CURRENT_DATE(),
    note_priority VARCHAR(50) DEFAULT 'NORMAL',  -- Low, Normal, High, Urgent
    requires_review BOOLEAN DEFAULT FALSE,
    reviewed_by VARCHAR(255),
    reviewed_date TIMESTAMP_NTZ,
    review_comments TEXT,
    flagged_for_followup BOOLEAN DEFAULT FALSE,
    followup_due_date DATE,
    followup_completed BOOLEAN DEFAULT FALSE,
    tags ARRAY,  -- Searchable tags
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_by VARCHAR(255),
    modified_date TIMESTAMP_NTZ,
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id),
    FOREIGN KEY (participant_id) REFERENCES PARTICIPANTS(participant_id),
    FOREIGN KEY (observation_id) REFERENCES OBSERVATIONS(observation_id)
);

-- ============================================================================
-- Clinical Findings
-- ============================================================================

CREATE OR REPLACE TABLE FINDINGS (
    finding_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_id VARCHAR(50),
    finding_type VARCHAR(100),  -- Adverse Event, Efficacy Outcome, Lab Abnormality
    finding_category VARCHAR(100),  -- Safety, Efficacy, Quality
    finding_description TEXT NOT NULL,
    severity VARCHAR(50),  -- Mild, Moderate, Severe
    relationship_to_intervention VARCHAR(100),  -- Not Related, Possibly, Probably, Definitely
    action_taken TEXT,
    outcome VARCHAR(100),  -- Resolved, Ongoing, Fatal, Unknown
    outcome_date DATE,
    reported_to_irb BOOLEAN DEFAULT FALSE,
    irb_report_date DATE,
    sae_reported BOOLEAN DEFAULT FALSE,  -- Serious Adverse Event
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_by VARCHAR(255),
    modified_date TIMESTAMP_NTZ,
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id),
    FOREIGN KEY (participant_id) REFERENCES PARTICIPANTS(participant_id)
);

-- ============================================================================
-- File Attachments
-- ============================================================================

CREATE OR REPLACE TABLE ATTACHMENTS (
    attachment_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_id VARCHAR(50),
    note_id VARCHAR(50),
    finding_id VARCHAR(50),
    file_name VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),  -- PDF, PNG, JPEG, XLSX, DOCX
    file_size_bytes BIGINT,
    file_path VARCHAR(1000),  -- Path in stage
    file_description TEXT,
    uploaded_by VARCHAR(255) DEFAULT CURRENT_USER(),
    uploaded_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id),
    FOREIGN KEY (participant_id) REFERENCES PARTICIPANTS(participant_id),
    FOREIGN KEY (note_id) REFERENCES RESEARCH_NOTES(note_id),
    FOREIGN KEY (finding_id) REFERENCES FINDINGS(finding_id)
);

-- ============================================================================
-- Study Protocol Definitions
-- ============================================================================

CREATE OR REPLACE TABLE STUDY_PROTOCOLS (
    protocol_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    protocol_version VARCHAR(50),
    visit_schedule VARIANT,  -- JSON array of planned visits
    data_collection_forms VARIANT,  -- JSON definition of forms
    inclusion_criteria ARRAY,
    exclusion_criteria ARRAY,
    primary_endpoints ARRAY,
    secondary_endpoints ARRAY,
    sample_size_calculation TEXT,
    statistical_analysis_plan TEXT,
    protocol_document_path VARCHAR(1000),
    approved_date DATE,
    approved_by VARCHAR(255),
    effective_date DATE,
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id)
);

-- ============================================================================
-- Data Quality Issues
-- ============================================================================

CREATE OR REPLACE TABLE DATA_QUALITY_ISSUES (
    issue_id VARCHAR(50) PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    participant_id VARCHAR(50),
    observation_id VARCHAR(50),
    issue_type VARCHAR(100),  -- Missing Data, Out of Range, Inconsistent, Duplicate
    issue_description TEXT,
    issue_severity VARCHAR(50),  -- Low, Medium, High, Critical
    issue_status VARCHAR(50) DEFAULT 'OPEN',  -- Open, In Review, Resolved, Closed
    identified_by VARCHAR(255) DEFAULT CURRENT_USER(),
    identified_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    assigned_to VARCHAR(255),
    resolution TEXT,
    resolved_by VARCHAR(255),
    resolved_date TIMESTAMP_NTZ,
    metadata VARIANT,
    FOREIGN KEY (study_id) REFERENCES STUDIES(study_id),
    FOREIGN KEY (participant_id) REFERENCES PARTICIPANTS(participant_id),
    FOREIGN KEY (observation_id) REFERENCES OBSERVATIONS(observation_id)
);

-- ============================================================================
-- Comments and Collaboration
-- ============================================================================

CREATE OR REPLACE TABLE COMMENTS (
    comment_id VARCHAR(50) PRIMARY KEY,
    parent_type VARCHAR(50),  -- STUDY, PARTICIPANT, OBSERVATION, NOTE, FINDING
    parent_id VARCHAR(50) NOT NULL,
    comment_text TEXT NOT NULL,
    comment_type VARCHAR(50) DEFAULT 'GENERAL',  -- General, Question, Clarification, Issue
    mentions ARRAY,  -- @username mentions
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_date TIMESTAMP_NTZ
);

-- ============================================================================
-- Saved Searches and Filters
-- ============================================================================

CREATE OR REPLACE TABLE SAVED_SEARCHES (
    search_id VARCHAR(50) PRIMARY KEY,
    search_name VARCHAR(255) NOT NULL,
    search_description TEXT,
    search_criteria VARIANT,  -- JSON with filter criteria
    created_by VARCHAR(255) DEFAULT CURRENT_USER(),
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    is_public BOOLEAN DEFAULT FALSE,
    use_count INTEGER DEFAULT 0,
    last_used TIMESTAMP_NTZ
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Note: Snowflake uses micro-partitions and clustering
-- Create clustering keys for frequently filtered columns

ALTER TABLE OBSERVATIONS CLUSTER BY (study_id, observation_date);
ALTER TABLE RESEARCH_NOTES CLUSTER BY (study_id, note_date);
ALTER TABLE PARTICIPANTS CLUSTER BY (study_id);

-- ============================================================================
-- Summary
-- ============================================================================

SELECT 'Core Tables Created Successfully!' as status;

SELECT 
    table_schema,
    COUNT(*) as table_count
FROM CLINICAL_RESEARCH.INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'CLINICAL_RESEARCH'
    AND table_type = 'BASE TABLE'
GROUP BY table_schema
ORDER BY table_schema;

-- Show all tables
SHOW TABLES IN DATABASE CLINICAL_RESEARCH;

