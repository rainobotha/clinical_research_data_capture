-- ============================================================================
-- Clinical Research Data Capture - Streamlit Deployment
-- ============================================================================
-- Deploys the Streamlit application in Snowflake
--
-- Execute as: ACCOUNTADMIN role
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RESEARCH_WH;
USE DATABASE CLINICAL_RESEARCH;
USE SCHEMA APPS;

-- ============================================================================
-- Create Streamlit App
-- ============================================================================

-- Create stage for app files
CREATE STAGE IF NOT EXISTS APP_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for Streamlit application files';

-- Create the Streamlit app (via Snowsight UI or CLI)
-- Note: Use Snowsight UI or Snowflake CLI for actual deployment
-- This is documentation of the command structure
/*
-- If deploying via SQL, use this pattern:
-- First drop if exists (Streamlit apps can be dropped)
-- DROP STREAMLIT IF EXISTS CLINICAL_RESEARCH_APP;

CREATE STREAMLIT CLINICAL_RESEARCH_APP
    ROOT_LOCATION = '@CLINICAL_RESEARCH.APPS.APP_STAGE'
    MAIN_FILE = '/clinical_research_app.py'
    QUERY_WAREHOUSE = RESEARCH_WH
    TITLE = 'Clinical Research Data Capture'
    COMMENT = 'Clinical research notes and findings capture system - replaces spreadsheets';
*/

-- ============================================================================
-- Grant Permissions to Streamlit App
-- ============================================================================

-- Grant database and schema access to application
GRANT USAGE ON DATABASE CLINICAL_RESEARCH TO APPLICATION ROLE APP_PUBLIC;

GRANT USAGE ON SCHEMA CLINICAL_RESEARCH.RESEARCH_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT USAGE ON SCHEMA CLINICAL_RESEARCH.REFERENCE_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT USAGE ON SCHEMA CLINICAL_RESEARCH.AUDIT TO APPLICATION ROLE APP_PUBLIC;
GRANT USAGE ON SCHEMA CLINICAL_RESEARCH.STAGING TO APPLICATION ROLE APP_PUBLIC;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA CLINICAL_RESEARCH.RESEARCH_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA CLINICAL_RESEARCH.REFERENCE_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA CLINICAL_RESEARCH.AUDIT TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA CLINICAL_RESEARCH.STAGING TO APPLICATION ROLE APP_PUBLIC;

-- Grant view permissions
GRANT SELECT ON ALL VIEWS IN SCHEMA CLINICAL_RESEARCH.AUDIT TO APPLICATION ROLE APP_PUBLIC;

-- Grant future objects
GRANT SELECT, INSERT, UPDATE ON FUTURE TABLES IN SCHEMA CLINICAL_RESEARCH.RESEARCH_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT ON FUTURE TABLES IN SCHEMA CLINICAL_RESEARCH.REFERENCE_DATA TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT, INSERT ON FUTURE TABLES IN SCHEMA CLINICAL_RESEARCH.AUDIT TO APPLICATION ROLE APP_PUBLIC;

-- Grant procedure execution
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CLINICAL_RESEARCH.AUDIT TO APPLICATION ROLE APP_PUBLIC;

-- ============================================================================
-- Grant Access to Roles
-- ============================================================================

-- Make app available to research roles
GRANT USAGE ON STREAMLIT CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP TO ROLE PRINCIPAL_INVESTIGATOR;
GRANT USAGE ON STREAMLIT CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP TO ROLE RESEARCHER;
GRANT USAGE ON STREAMLIT CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP TO ROLE DATA_MANAGER;
GRANT USAGE ON STREAMLIT CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP TO ROLE RESEARCH_VIEWER;
GRANT USAGE ON STREAMLIT CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP TO ROLE RESEARCH_ADMIN;

-- ============================================================================
-- Deployment Instructions
-- ============================================================================

SELECT '
=== Streamlit in Snowflake Deployment Instructions ===

METHOD 1: SNOWSIGHT UI (Recommended)

1. Navigate to Snowsight > Streamlit
2. Click "+ Streamlit App"
3. Configure:
   - App name: CLINICAL_RESEARCH_APP
   - Location: 
     * Database: CLINICAL_RESEARCH
     * Schema: APPS
   - Warehouse: RESEARCH_WH
4. Upload file: clinical_research_app.py
5. Click "Create"

METHOD 2: SNOWFLAKE CLI

# Install CLI
pip install snowflake-cli-labs

# Configure connection
snow connection add --connection-name clinical_research \\
  --account YOUR_ACCOUNT \\
  --user YOUR_USER \\
  --role ACCOUNTADMIN \\
  --warehouse RESEARCH_WH \\
  --database CLINICAL_RESEARCH \\
  --schema APPS

# Deploy
cd /path/to/clinical_research_capture
snow streamlit deploy --connection clinical_research --replace

METHOD 3: SNOWSQL

# Upload file to stage
PUT file:///path/to/clinical_research_app.py 
  @CLINICAL_RESEARCH.APPS.APP_STAGE 
  AUTO_COMPRESS=FALSE 
  OVERWRITE=TRUE;

# Then create app via Snowsight UI

=== Post-Deployment Steps ===

1. GRANT ACCESS TO USERS

-- Grant to specific users
GRANT ROLE RESEARCHER TO USER researcher1;
GRANT ROLE RESEARCHER TO USER researcher2;
GRANT ROLE PRINCIPAL_INVESTIGATOR TO USER pi_user;

2. CREATE INITIAL STUDY

-- PIs can create studies through the app
-- Or create via SQL for initial setup

3. GRANT STUDY ACCESS

-- Grant users access to specific studies
INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.USER_STUDY_ACCESS
  (user_name, study_id, access_role, is_active)
VALUES
  (''researcher1'', ''STD_001'', ''RESEARCHER'', TRUE);

4. TEST THE APP

-- Access via: Snowsight > Streamlit Apps > CLINICAL_RESEARCH_APP
-- Test each feature:
  ✓ Create study
  ✓ Enroll participant
  ✓ Enter observation
  ✓ Create note
  ✓ Record finding
  ✓ Search data
  ✓ Generate report
  ✓ Export data

5. USER TRAINING

-- Provide training to research staff
-- Share user guide: docs/user_guide.md
-- Schedule Q&A session

=== Monitoring ===

-- Monitor app usage
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.STREAMLIT_APP_USAGE_HISTORY
WHERE APP_NAME = ''CLINICAL_RESEARCH_APP''
ORDER BY START_TIME DESC;

-- Monitor data entry activity
SELECT * FROM CLINICAL_RESEARCH.AUDIT.VW_USER_ACTIVITY_SUMMARY;

-- Check for errors
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE EXECUTION_CONTEXT = ''STREAMLIT''
  AND EXECUTION_STATUS != ''SUCCESS''
ORDER BY START_TIME DESC;

=== Support ===

For issues or questions:
- In-app help: Click ? icons
- Email: research.support@example.org
- Admin guide: docs/admin_guide.md

' as deployment_guide;

