-- ============================================================================
-- Clinical Research Data Capture - Database Setup
-- ============================================================================
-- This script creates the foundation for clinical research data management
-- Replacing spreadsheet-based workflows with structured database
--
-- Execute as: ACCOUNTADMIN role
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Create warehouse for research operations
CREATE WAREHOUSE IF NOT EXISTS RESEARCH_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for clinical research data capture';

USE WAREHOUSE RESEARCH_WH;

-- ============================================================================
-- Main Database
-- ============================================================================

CREATE DATABASE IF NOT EXISTS CLINICAL_RESEARCH
    COMMENT = 'Clinical research data capture system - replaces spreadsheets';

USE DATABASE CLINICAL_RESEARCH;

-- Core data schema
CREATE SCHEMA IF NOT EXISTS RESEARCH_DATA
    COMMENT = 'Clinical research studies, participants, and findings';

-- Reference data schema
CREATE SCHEMA IF NOT EXISTS REFERENCE_DATA
    COMMENT = 'Controlled vocabularies and lookup tables';

-- Application schema
CREATE SCHEMA IF NOT EXISTS APPS
    COMMENT = 'Streamlit applications';

-- Audit schema
CREATE SCHEMA IF NOT EXISTS AUDIT
    COMMENT = 'Audit trail and compliance logging';

-- Staging schema for imports
CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Temporary staging for spreadsheet imports';

-- ============================================================================
-- Roles and Access Control
-- ============================================================================

-- Principal Investigator - full control of their studies
CREATE ROLE IF NOT EXISTS PRINCIPAL_INVESTIGATOR
    COMMENT = 'Principal Investigators - full access to their studies';

-- Researcher - data entry and view
CREATE ROLE IF NOT EXISTS RESEARCHER
    COMMENT = 'Research staff - data entry and viewing';

-- Data Manager - data quality and validation
CREATE ROLE IF NOT EXISTS DATA_MANAGER
    COMMENT = 'Data managers - quality control and validation';

-- Viewer - read-only access
CREATE ROLE IF NOT EXISTS RESEARCH_VIEWER
    COMMENT = 'Viewers - read-only access for monitoring and auditing';

-- System Admin - system administration
CREATE ROLE IF NOT EXISTS RESEARCH_ADMIN
    COMMENT = 'System administrators for clinical research system';

-- Grant role hierarchy
GRANT ROLE RESEARCHER TO ROLE PRINCIPAL_INVESTIGATOR;
GRANT ROLE RESEARCH_VIEWER TO ROLE DATA_MANAGER;
GRANT ROLE RESEARCH_ADMIN TO ROLE ACCOUNTADMIN;

-- Grant database access
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO ROLE RESEARCH_ADMIN;
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO ROLE PRINCIPAL_INVESTIGATOR;
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO ROLE RESEARCHER;
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO ROLE DATA_MANAGER;
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO ROLE RESEARCH_VIEWER;

-- Grant warehouse access
GRANT USAGE ON WAREHOUSE RESEARCH_WH TO ROLE RESEARCH_ADMIN;
GRANT USAGE ON WAREHOUSE RESEARCH_WH TO ROLE PRINCIPAL_INVESTIGATOR;
GRANT USAGE ON WAREHOUSE RESEARCH_WH TO ROLE RESEARCHER;
GRANT USAGE ON WAREHOUSE RESEARCH_WH TO ROLE DATA_MANAGER;
GRANT USAGE ON WAREHOUSE RESEARCH_WH TO ROLE RESEARCH_VIEWER;

-- ============================================================================
-- File Formats for Imports/Exports
-- ============================================================================

CREATE FILE FORMAT IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = AUTO
    COMMENT = 'CSV format for spreadsheet imports';

CREATE FILE FORMAT IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.EXCEL_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    COMMENT = 'Format for Excel exports';

CREATE FILE FORMAT IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.JSON_FORMAT
    TYPE = JSON
    COMPRESSION = AUTO
    COMMENT = 'JSON format for structured data';

-- ============================================================================
-- Stages for File Management
-- ============================================================================

-- Stage for file attachments
CREATE STAGE IF NOT EXISTS CLINICAL_RESEARCH.RESEARCH_DATA.ATTACHMENTS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Storage for research document attachments (images, PDFs, etc.)';

-- Stage for spreadsheet imports
CREATE STAGE IF NOT EXISTS CLINICAL_RESEARCH.STAGING.IMPORT_STAGE
    FILE_FORMAT = CLINICAL_RESEARCH.REFERENCE_DATA.CSV_FORMAT
    COMMENT = 'Staging area for bulk spreadsheet imports';

-- ============================================================================
-- Tags for Classification
-- ============================================================================

CREATE TAG IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.DATA_CLASSIFICATION
    ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'PHI'
    COMMENT = 'Data classification for clinical research';

CREATE TAG IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.PHI_INDICATOR
    ALLOWED_VALUES 'YES', 'NO', 'DE_IDENTIFIED'
    COMMENT = 'Protected Health Information indicator';

CREATE TAG IF NOT EXISTS CLINICAL_RESEARCH.REFERENCE_DATA.STUDY_PHASE
    ALLOWED_VALUES 'PLANNING', 'ACTIVE', 'ANALYSIS', 'COMPLETE', 'ARCHIVED'
    COMMENT = 'Research study phase';

-- ============================================================================
-- Summary
-- ============================================================================

SELECT 'Database Setup Complete!' as status,
       'Database: CLINICAL_RESEARCH' as database_name,
       'Schemas: 5 (RESEARCH_DATA, REFERENCE_DATA, APPS, AUDIT, STAGING)' as schemas,
       'Roles: 5 (PI, Researcher, Data Manager, Viewer, Admin)' as roles,
       'Ready for table creation' as next_step;

SHOW DATABASES LIKE 'CLINICAL_RESEARCH';
SHOW ROLES LIKE '%RESEARCH%';

