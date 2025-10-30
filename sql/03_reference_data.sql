-- ============================================================================
-- Clinical Research Data Capture - Reference Data
-- ============================================================================
-- Creates controlled vocabularies and lookup tables
-- Ensures data consistency and quality
--
-- Execute as: ACCOUNTADMIN or RESEARCH_ADMIN role
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RESEARCH_WH;
USE DATABASE CLINICAL_RESEARCH;
USE SCHEMA REFERENCE_DATA;

-- ============================================================================
-- Study Types
-- ============================================================================

CREATE OR REPLACE TABLE STUDY_TYPES (
    type_id VARCHAR(50) PRIMARY KEY,
    type_name VARCHAR(255) NOT NULL,
    type_description TEXT,
    regulatory_requirements TEXT,
    typical_duration_months INTEGER,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO STUDY_TYPES VALUES
    ('ST_001', 'Randomized Controlled Trial (RCT)', 
     'Participants randomly assigned to intervention or control groups', 
     'IRB approval, informed consent, trial registration', 24, TRUE),
    ('ST_002', 'Observational Study', 
     'Observe outcomes without intervention', 
     'IRB approval, informed consent', 12, TRUE),
    ('ST_003', 'Chart Review/Retrospective', 
     'Analysis of existing medical records', 
     'IRB approval, waiver of consent possible', 6, TRUE),
    ('ST_004', 'Case-Control Study', 
     'Compare subjects with condition to controls', 
     'IRB approval, informed consent', 12, TRUE),
    ('ST_005', 'Cohort Study', 
     'Follow group over time', 
     'IRB approval, informed consent', 36, TRUE),
    ('ST_006', 'Cross-Sectional Study', 
     'Snapshot at single point in time', 
     'IRB approval, informed consent', 3, TRUE),
    ('ST_007', 'Laboratory/Bench Research', 
     'In vitro or animal studies', 
     'IACUC approval if animals', 12, TRUE),
    ('ST_008', 'Quality Improvement', 
     'Healthcare quality improvement projects', 
     'May not require IRB', 6, TRUE);

-- ============================================================================
-- Observation Types
-- ============================================================================

CREATE OR REPLACE TABLE OBSERVATION_TYPES (
    obs_type_id VARCHAR(50) PRIMARY KEY,
    obs_type_name VARCHAR(255) NOT NULL,
    obs_category VARCHAR(100),  -- Safety, Efficacy, Quality of Life, Laboratory
    common_measurements ARRAY,  -- Common measurements for this type
    standard_units ARRAY,  -- Standard units of measure
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO OBSERVATION_TYPES 
SELECT 'OBS_001', 'Vital Signs', 'Safety', 
     ARRAY_CONSTRUCT('Blood Pressure', 'Heart Rate', 'Temperature', 'Respiratory Rate', 'O2 Saturation'),
     ARRAY_CONSTRUCT('mmHg', 'bpm', '°C', 'breaths/min', '%'), TRUE
UNION ALL
SELECT 'OBS_002', 'Laboratory Results', 'Safety',
     ARRAY_CONSTRUCT('CBC', 'Comprehensive Metabolic Panel', 'Lipid Panel', 'HbA1c'),
     ARRAY_CONSTRUCT('cells/μL', 'mg/dL', 'mmol/L', '%'), TRUE
UNION ALL
SELECT 'OBS_003', 'Physical Examination', 'Safety',
     ARRAY_CONSTRUCT('General Appearance', 'Cardiovascular', 'Respiratory', 'Neurological'),
     ARRAY_CONSTRUCT('Normal/Abnormal', 'Description'), TRUE
UNION ALL
SELECT 'OBS_004', 'Efficacy Assessment', 'Efficacy',
     ARRAY_CONSTRUCT('Primary Outcome', 'Secondary Outcome', 'Response Rate'),
     ARRAY_CONSTRUCT('Score', 'Yes/No', 'Percentage'), TRUE
UNION ALL
SELECT 'OBS_005', 'Quality of Life', 'Quality of Life',
     ARRAY_CONSTRUCT('Physical Function', 'Mental Health', 'Pain Level', 'Social Function'),
     ARRAY_CONSTRUCT('Score 0-100', 'Score 1-10'), TRUE
UNION ALL
SELECT 'OBS_006', 'Adverse Event', 'Safety',
     ARRAY_CONSTRUCT('Event Description', 'Severity', 'Relationship', 'Action Taken'),
     ARRAY_CONSTRUCT('Text', 'Mild/Moderate/Severe', 'Related/Not Related', 'Text'), TRUE;

-- ============================================================================
-- Note Types
-- ============================================================================

CREATE OR REPLACE TABLE NOTE_TYPES (
    note_type_id VARCHAR(50) PRIMARY KEY,
    note_type_name VARCHAR(255) NOT NULL,
    note_category VARCHAR(100),
    requires_review BOOLEAN DEFAULT FALSE,
    template_text TEXT,  -- Optional template for structured notes
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO NOTE_TYPES VALUES
    ('NT_001', 'Progress Note', 'Clinical', FALSE, 
     'Date: [DATE]\nParticipant: [ID]\nObservations:\n\nAssessment:\n\nPlan:', TRUE),
    ('NT_002', 'Adverse Event Note', 'Safety', TRUE,
     'Event Description:\nOnset Date:\nSeverity:\nRelationship to Study:\nAction Taken:\nOutcome:', TRUE),
    ('NT_003', 'Protocol Deviation', 'Compliance', TRUE,
     'Deviation Description:\nDate Occurred:\nReason:\nImpact Assessment:\nCorrective Action:', TRUE),
    ('NT_004', 'Study Finding', 'Research', FALSE,
     'Finding:\nEvidence:\nImplications:\nNext Steps:', TRUE),
    ('NT_005', 'Consent Issue', 'Regulatory', TRUE,
     'Issue Description:\nParticipant Impact:\nResolution:', TRUE),
    ('NT_006', 'Data Query', 'Quality', FALSE,
     'Query:\nData Point:\nIssue:\nResolution:', TRUE),
    ('NT_007', 'General Observation', 'Clinical', FALSE, NULL, TRUE);

-- ============================================================================
-- Finding Classifications
-- ============================================================================

CREATE OR REPLACE TABLE FINDING_CLASSIFICATIONS (
    classification_id VARCHAR(50) PRIMARY KEY,
    classification_name VARCHAR(255) NOT NULL,
    classification_category VARCHAR(100),
    severity_levels ARRAY,
    reporting_requirements TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO FINDING_CLASSIFICATIONS 
SELECT 'FC_001', 'Adverse Event', 'Safety',
     ARRAY_CONSTRUCT('Mild', 'Moderate', 'Severe'),
     'Report to IRB if serious (death, hospitalization, disability)', TRUE
UNION ALL
SELECT 'FC_002', 'Serious Adverse Event (SAE)', 'Safety',
     ARRAY_CONSTRUCT('Death', 'Life-threatening', 'Hospitalization', 'Disability', 'Congenital Anomaly'),
     'Report to IRB within 24 hours, sponsor notification required', TRUE
UNION ALL
SELECT 'FC_003', 'Efficacy Outcome', 'Efficacy',
     ARRAY_CONSTRUCT('Complete Response', 'Partial Response', 'Stable Disease', 'Progressive Disease'),
     'Document per protocol schedule', TRUE
UNION ALL
SELECT 'FC_004', 'Laboratory Abnormality', 'Safety',
     ARRAY_CONSTRUCT('Grade 1', 'Grade 2', 'Grade 3', 'Grade 4'),
     'Grade 3+ requires clinical assessment and documentation', TRUE
UNION ALL
SELECT 'FC_005', 'Protocol Deviation', 'Compliance',
     ARRAY_CONSTRUCT('Minor', 'Major', 'Critical'),
     'Major/Critical require IRB reporting', TRUE;

-- ============================================================================
-- Units of Measure
-- ============================================================================

CREATE OR REPLACE TABLE UNITS_OF_MEASURE (
    unit_id VARCHAR(50) PRIMARY KEY,
    unit_name VARCHAR(100) NOT NULL,
    unit_category VARCHAR(100),  -- Vital Signs, Laboratory, Weight, Volume, etc.
    unit_abbreviation VARCHAR(20),
    conversion_to_si FLOAT,  -- Conversion factor to SI units
    si_unit VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO UNITS_OF_MEASURE VALUES
    ('UNIT_001', 'Millimeters of Mercury', 'Blood Pressure', 'mmHg', 1.0, 'mmHg', TRUE),
    ('UNIT_002', 'Beats Per Minute', 'Heart Rate', 'bpm', 1.0, 'bpm', TRUE),
    ('UNIT_003', 'Degrees Celsius', 'Temperature', '°C', 1.0, '°C', TRUE),
    ('UNIT_004', 'Degrees Fahrenheit', 'Temperature', '°F', 0.556, '°C', TRUE),
    ('UNIT_005', 'Kilograms', 'Weight', 'kg', 1.0, 'kg', TRUE),
    ('UNIT_006', 'Pounds', 'Weight', 'lbs', 0.454, 'kg', TRUE),
    ('UNIT_007', 'Milligrams per Deciliter', 'Laboratory', 'mg/dL', 1.0, 'mg/dL', TRUE),
    ('UNIT_008', 'Millimoles per Liter', 'Laboratory', 'mmol/L', 1.0, 'mmol/L', TRUE),
    ('UNIT_009', 'Cells per Microliter', 'Laboratory', 'cells/μL', 1.0, 'cells/μL', TRUE),
    ('UNIT_010', 'Percentage', 'General', '%', 1.0, '%', TRUE);

-- ============================================================================
-- Normal Ranges (Reference Ranges)
-- ============================================================================

CREATE OR REPLACE TABLE NORMAL_RANGES (
    range_id VARCHAR(50) PRIMARY KEY,
    measurement_name VARCHAR(255) NOT NULL,
    demographic_group VARCHAR(100),  -- Adult Male, Adult Female, Pediatric, etc.
    lower_limit FLOAT,
    upper_limit FLOAT,
    unit VARCHAR(50),
    interpretation_low VARCHAR(255),
    interpretation_high VARCHAR(255),
    source VARCHAR(255),  -- Clinical laboratory, published guidelines, etc.
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO NORMAL_RANGES VALUES
    ('NR_001', 'Systolic Blood Pressure', 'Adult', 90, 120, 'mmHg', 'Hypotension', 'Hypertension', 'AHA Guidelines', TRUE),
    ('NR_002', 'Diastolic Blood Pressure', 'Adult', 60, 80, 'mmHg', 'Hypotension', 'Hypertension', 'AHA Guidelines', TRUE),
    ('NR_003', 'Heart Rate', 'Adult', 60, 100, 'bpm', 'Bradycardia', 'Tachycardia', 'Clinical Standard', TRUE),
    ('NR_004', 'Temperature', 'Adult', 36.1, 37.2, '°C', 'Hypothermia', 'Fever', 'Clinical Standard', TRUE),
    ('NR_005', 'Glucose (Fasting)', 'Adult', 70, 100, 'mg/dL', 'Hypoglycemia', 'Hyperglycemia', 'ADA Guidelines', TRUE),
    ('NR_006', 'Hemoglobin', 'Adult Male', 13.5, 17.5, 'g/dL', 'Anemia', 'Polycythemia', 'Clinical Lab', TRUE),
    ('NR_007', 'Hemoglobin', 'Adult Female', 12.0, 15.5, 'g/dL', 'Anemia', 'Polycythemia', 'Clinical Lab', TRUE),
    ('NR_008', 'White Blood Count', 'Adult', 4.5, 11.0, '×10³/μL', 'Leukopenia', 'Leukocytosis', 'Clinical Lab', TRUE);

-- ============================================================================
-- User Preferences
-- ============================================================================

CREATE OR REPLACE TABLE USER_PREFERENCES (
    user_name VARCHAR(255) PRIMARY KEY,
    default_study_id VARCHAR(50),
    dashboard_layout VARIANT,  -- JSON with widget preferences
    notification_preferences VARIANT,  -- Email, in-app, frequency
    favorite_searches ARRAY,
    recent_studies ARRAY,
    ui_theme VARCHAR(50) DEFAULT 'light',
    rows_per_page INTEGER DEFAULT 25,
    date_format VARCHAR(50) DEFAULT 'YYYY-MM-DD',
    timezone VARCHAR(100) DEFAULT 'UTC',
    last_login TIMESTAMP_NTZ,
    preferences_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- Data Validation Rules
-- ============================================================================

CREATE OR REPLACE TABLE VALIDATION_RULES (
    rule_id VARCHAR(50) PRIMARY KEY,
    rule_name VARCHAR(255) NOT NULL,
    applies_to VARCHAR(100),  -- Table name
    column_name VARCHAR(255),
    rule_type VARCHAR(50),  -- REQUIRED, RANGE, FORMAT, CUSTOM
    rule_definition VARIANT,  -- JSON with rule details
    error_message VARCHAR(500),
    severity VARCHAR(50) DEFAULT 'ERROR',  -- ERROR, WARNING, INFO
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO VALIDATION_RULES 
SELECT 'VR_001', 'Study Name Required', 'STUDIES', 'study_name', 'REQUIRED',
     PARSE_JSON('{"min_length": 5, "max_length": 500}'),
     'Study name is required and must be 5-500 characters', 'ERROR', TRUE, CURRENT_TIMESTAMP()
UNION ALL
SELECT 'VR_002', 'IRB Approval for Active Studies', 'STUDIES', 'irb_approval_number', 'REQUIRED',
     PARSE_JSON('{"condition": "study_status = ACTIVE"}'),
     'Active studies must have IRB approval number', 'ERROR', TRUE, CURRENT_TIMESTAMP()
UNION ALL
SELECT 'VR_003', 'Valid Blood Pressure Range', 'OBSERVATIONS', 'measurement_value', 'RANGE',
     PARSE_JSON('{"min": 40, "max": 250, "applies_when": "measurement_name = Blood Pressure"}'),
     'Blood pressure must be between 40-250 mmHg', 'WARNING', TRUE, CURRENT_TIMESTAMP()
UNION ALL
SELECT 'VR_004', 'Future Dates Not Allowed', 'OBSERVATIONS', 'observation_date', 'CUSTOM',
     PARSE_JSON('{"rule": "observation_date <= CURRENT_DATE()"}'),
     'Observation date cannot be in the future', 'ERROR', TRUE, CURRENT_TIMESTAMP()
UNION ALL
SELECT 'VR_005', 'Participant Must Exist', 'OBSERVATIONS', 'participant_id', 'FOREIGN_KEY',
     PARSE_JSON('{"references": "PARTICIPANTS(participant_id)"}'),
     'Participant must be enrolled in study', 'ERROR', TRUE, CURRENT_TIMESTAMP();

-- ============================================================================
-- Data Entry Templates
-- ============================================================================

CREATE OR REPLACE TABLE FORM_TEMPLATES (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(255) NOT NULL,
    template_category VARCHAR(100),
    study_type VARCHAR(100),  -- Which study types use this template
    form_structure VARIANT,  -- JSON definition of form fields
    validation_rules ARRAY,  -- References to validation rules
    help_text TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Vital Signs Template
INSERT INTO FORM_TEMPLATES 
SELECT 'TMPL_001', 'Vital Signs Collection', 'Clinical Assessment', 'All',
     PARSE_JSON('{
         "fields": [
             {"name": "blood_pressure_systolic", "type": "number", "label": "Systolic BP", "unit": "mmHg", "required": true},
             {"name": "blood_pressure_diastolic", "type": "number", "label": "Diastolic BP", "unit": "mmHg", "required": true},
             {"name": "heart_rate", "type": "number", "label": "Heart Rate", "unit": "bpm", "required": true},
             {"name": "temperature", "type": "number", "label": "Temperature", "unit": "°C", "required": true},
             {"name": "respiratory_rate", "type": "number", "label": "Respiratory Rate", "unit": "breaths/min", "required": false},
             {"name": "o2_saturation", "type": "number", "label": "O2 Saturation", "unit": "%", "required": false}
         ]
     }'),
     ARRAY_CONSTRUCT('VR_003', 'VR_004'),
     'Standard vital signs measurement form. Take measurements in same position and time of day when possible.',
     TRUE, CURRENT_TIMESTAMP();

-- Adverse Event Template
INSERT INTO FORM_TEMPLATES 
SELECT 'TMPL_002', 'Adverse Event Report', 'Safety', 'Clinical Trial',
     PARSE_JSON('{
         "fields": [
             {"name": "event_description", "type": "text", "label": "Event Description", "required": true},
             {"name": "onset_date", "type": "date", "label": "Onset Date", "required": true},
             {"name": "severity", "type": "select", "label": "Severity", "options": ["Mild", "Moderate", "Severe"], "required": true},
             {"name": "relationship", "type": "select", "label": "Relationship to Intervention", "options": ["Not Related", "Unlikely", "Possible", "Probable", "Definite"], "required": true},
             {"name": "action_taken", "type": "text", "label": "Action Taken", "required": true},
             {"name": "outcome", "type": "select", "label": "Outcome", "options": ["Resolved", "Resolving", "Not Resolved", "Fatal", "Unknown"], "required": true},
             {"name": "sae", "type": "checkbox", "label": "Serious Adverse Event (SAE)", "required": true}
         ]
     }'),
     ARRAY_CONSTRUCT('VR_004'),
     'Report all adverse events, regardless of relationship to study intervention. SAEs must be reported within 24 hours.',
     TRUE, CURRENT_TIMESTAMP();

-- ============================================================================
-- Common Abbreviations and Terminology
-- ============================================================================

CREATE OR REPLACE TABLE MEDICAL_ABBREVIATIONS (
    abbreviation VARCHAR(50) PRIMARY KEY,
    full_term VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    definition TEXT,
    example_usage VARCHAR(500)
);

INSERT INTO MEDICAL_ABBREVIATIONS VALUES
    ('AE', 'Adverse Event', 'Safety', 'Any untoward medical occurrence', 'Patient experienced AE of headache'),
    ('SAE', 'Serious Adverse Event', 'Safety', 'AE resulting in death, hospitalization, or disability', 'SAE reported to IRB within 24h'),
    ('IRB', 'Institutional Review Board', 'Regulatory', 'Ethics committee reviewing research', 'Study approved by IRB on 2024-01-15'),
    ('ICF', 'Informed Consent Form', 'Regulatory', 'Document explaining study to participant', 'ICF signed before enrollment'),
    ('PI', 'Principal Investigator', 'Study Role', 'Lead researcher responsible for study', 'Dr. Smith is the PI'),
    ('CRA', 'Clinical Research Associate', 'Study Role', 'Monitor ensuring protocol compliance', 'CRA conducted site visit'),
    ('CRF', 'Case Report Form', 'Data Collection', 'Form for collecting clinical data', 'Data entered into CRF'),
    ('GCP', 'Good Clinical Practice', 'Regulatory', 'International quality standards', 'Study conducted per GCP guidelines'),
    ('SOC', 'System Organ Class', 'Classification', 'High-level categorization of medical conditions', 'AE classified by SOC'),
    ('MedDRA', 'Medical Dictionary for Regulatory Activities', 'Classification', 'Standard medical terminology', 'Coded using MedDRA version 25.0');

-- ============================================================================
-- Summary
-- ============================================================================

SELECT 'Reference Data Populated Successfully!' as status;

SELECT 
    'Study Types: ' || (SELECT COUNT(*) FROM STUDY_TYPES) as study_types,
    'Observation Types: ' || (SELECT COUNT(*) FROM OBSERVATION_TYPES) as observation_types,
    'Note Types: ' || (SELECT COUNT(*) FROM NOTE_TYPES) as note_types,
    'Units of Measure: ' || (SELECT COUNT(*) FROM UNITS_OF_MEASURE) as units,
    'Normal Ranges: ' || (SELECT COUNT(*) FROM NORMAL_RANGES) as normal_ranges,
    'Form Templates: ' || (SELECT COUNT(*) FROM FORM_TEMPLATES) as templates;

-- Show reference tables
SHOW TABLES IN SCHEMA CLINICAL_RESEARCH.REFERENCE_DATA;

