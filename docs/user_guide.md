# Clinical Research Data Capture - User Guide

## Welcome!

This guide will help you transition from spreadsheet-based data collection to the Clinical Research Data Capture system.

## Getting Started

### Accessing the Application

1. **Log into Snowflake** (Snowsight interface)
2. Click **"Streamlit"** in the left navigation
3. Click **"Clinical Research Data Capture"**
4. The application opens in your browser

**URL Format:**
```
https://app.snowflake.com/REGION/ACCOUNT/#/streamlit-apps/CLINICAL_RESEARCH.APPS.CLINICAL_RESEARCH_APP
```

### Your First Login

1. **Check your role** in the sidebar (should be RESEARCHER or PRINCIPAL_INVESTIGATOR)
2. **Select a study** from Study Management page
3. **Explore the dashboard** to familiarize yourself
4. **Try entering a quick note** to test the system

## Main Pages

### 📊 Dashboard

**What it shows:**
- Number of active studies
- Total participants
- Recent notes and findings
- Your activity summary

**Use it to:**
- Get quick overview of all research activity
- See recent data entries
- Check study status at a glance

### 📚 Study Management

#### Creating a New Study

1. Go to **Study Management** > **Create New Study** tab
2. Fill in required fields:
   - **Study Name**: Descriptive name (e.g., "Diabetes Prevention Trial 2024")
   - **Protocol Number**: Your IRB approval number
   - **Principal Investigator**: Your name or PI's name
   - **Study Type**: Select from dropdown
   - **Study Phase**: Planning, Active, Analysis, or Complete
3. Enter optional fields:
   - IRB approval details
   - Start and end dates
   - Target enrollment
   - Study description
4. Click **"Create Study"**
5. Study is created and automatically selected

#### Selecting a Study

1. Go to **Active Studies** tab
2. Browse list of studies you have access to
3. Click **"Select"** button next to the study you want to work on
4. Selected study appears in sidebar

**💡 Tip**: Always check the sidebar to see which study is currently selected!

### ✍️ Data Entry

**Before you start:** Make sure you have a study selected (check sidebar)

#### Quick Research Note

**Use for**: General observations, progress notes, comments

**Steps:**
1. Go to **Data Entry** > **Quick Note** tab
2. Select **Note Type** (Progress Note, Adverse Event Note, etc.)
3. Select **Participant** (or choose "Study-Level Note")
4. Enter **Note Title** (brief summary)
5. Enter **Note Content** (detailed observations)
6. Set **Priority** if needed
7. Check boxes if:
   - Note requires review by PI/Data Manager
   - Needs follow-up (set due date)
8. Add **Tags** for easy searching (optional)
9. Click **"Save Note"**

**✅ Success** = Green confirmation message appears

#### Clinical Observation

**Use for**: Vital signs, lab results, assessments

**Steps:**
1. Go to **Data Entry** > **Observation** tab
2. Select **Participant**
3. Enter **Observation Date** and **Time**
4. Enter **Visit Number** and **Name** (e.g., "Baseline Visit")
5. Select **Observation Type** (Vital Signs, Lab Results, etc.)
6. Enter **Measurement**:
   - Measurement name (e.g., "Systolic Blood Pressure")
   - Value (e.g., "120")
   - Unit (e.g., "mmHg")
7. Check **Clinically Significant** if abnormal
8. Add any **Notes** about the measurement
9. Click **"Save Observation"**

**📊 Validation**: System will warn if value is outside normal range

#### Clinical Finding

**Use for**: Adverse events, efficacy outcomes, protocol deviations

**Steps:**
1. Go to **Data Entry** > **Finding** tab
2. Select **Participant** (or Study-Level)
3. Select **Finding Type**:
   - **Adverse Event**: Any untoward medical occurrence
   - **Efficacy Outcome**: Treatment response or outcome
   - **Lab Abnormality**: Abnormal lab result
   - **Protocol Deviation**: Deviation from protocol
4. Select **Severity** (Mild, Moderate, Severe)
5. For Adverse Events:
   - Select **Relationship to Intervention**
   - Check **SAE** if serious (death, hospitalization, etc.)
   - Indicate if **Reported to IRB**
6. Enter detailed **Description**
7. Document **Action Taken**
8. Select **Outcome** (Ongoing, Resolved, etc.)
9. Click **"Save Finding"**

**⚠️ IMPORTANT**: Serious Adverse Events (SAEs) must be reported to IRB within 24 hours!

#### Enrolling a Participant

**Steps:**
1. Go to **Data Entry** > **Participant** tab
2. Enter **Participant Study Number** (e.g., "001", "002")
3. Enter **Enrollment Date** (usually today)
4. Enter **Consent Date** (when consent was obtained)
5. Enter **Consent Version** (from your ICF)
6. Optional: Demographic group, randomization arm
7. Verify **Eligibility**:
   - Check "Inclusion Criteria Met"
   - Leave "Exclusion Criteria Met" unchecked
8. Click **"Enroll Participant"**

**✅ Auto-updates**: Enrollment count increases automatically

### 🔍 Search

#### Searching Notes

1. Go to **Search** > **Search Notes** tab
2. Enter **Search Text** (searches titles and content)
3. Filter by **Note Type** if desired
4. Set **Date Range**
5. Click **"Search Notes"**
6. Results appear in table below

**💡 Pro Tip**: Use tags for better searchability. Add tags when creating notes.

#### Searching Findings

1. Go to **Search** > **Search Findings** tab
2. Filter by **Finding Type** and **Severity**
3. Click **"Search Findings"**
4. SAEs are highlighted if present

#### Browsing Data

1. Go to **Search** > **Browse Data** tab
2. Select **Data Type** (Studies, Participants, Observations, etc.)
3. View all data in table
4. Click **"Export to CSV"** to download

### 📈 Reports

#### Study Summary Report

Shows overview of all your studies:
- Enrollment progress
- Data collection statistics
- Notes and findings count

#### Enrollment Tracking

Visual dashboard of enrollment progress:
- Bar charts showing current vs target
- Recent enrollment activity
- Enrollment by study

#### Safety Report

Critical for monitoring study safety:
- All adverse events
- Severity distribution
- SAE alerts
- IRB reporting status

**⚠️ Review regularly!**

#### Data Quality

Shows completeness and verification status:
- Total observations collected
- Percentage verified
- Items needing review

### 📤 Import/Export

#### Importing from Spreadsheets

**Migrating existing data:**

1. Go to **Import/Export** > **Import from Spreadsheet** tab
2. Select **Data Type** (Participants, Observations, or Notes)
3. Click **"Choose file"** and select your Excel/CSV file
4. **Preview** shows first 10 rows
5. **Map columns** from your spreadsheet to database fields
6. Click **"Import Data"**

**📋 Prepare your spreadsheet:**
- Remove blank rows
- Use consistent column names
- Ensure dates are formatted correctly
- Remove any formulas (values only)

**Supported formats:** CSV, XLSX (Excel)

#### Exporting to Excel

1. Go to **Import/Export** > **Export to Excel** tab
2. Select **Export Scope**:
   - Current Study Only
   - All My Studies
   - Custom Selection
3. Select **Data Types** to include
4. Check **Include Metadata** if you want audit fields
5. Click **"Generate Export"**
6. Click **"Download CSV"** button

**📧 Share exports carefully** - may contain sensitive data!

## Best Practices

### Data Entry

✅ **Do**:
- Enter data daily (don't let it accumulate)
- Use consistent terminology
- Add tags to notes for searchability
- Review data before marking as verified
- Use specific visit names (not just numbers)
- Document everything - if in doubt, add a note

❌ **Don't**:
- Enter dates in the future (system will reject)
- Skip required fields
- Use abbreviations without defining them first
- Delay entering adverse events
- Forget to save before navigating away

### Data Quality

**Review and verification:**
1. Data Managers periodically review observations
2. Mark data as "Verified" after review
3. Flag questionable data for follow-up
4. Resolve data quality issues promptly

**Completeness:**
- Aim for 100% completion of required fields
- If data is missing, document reason in notes
- Use "Unknown" or "Not Assessed" rather than leaving blank

### Safety Monitoring

**Adverse Events:**
- Report ALL adverse events, regardless of relationship
- Document even if "probably not related"
- Be specific in descriptions
- Update outcome as situation evolves

**Serious Adverse Events (SAEs):**
- ⚠️ Check the SAE box
- **Immediate**: Notify PI and IRB per protocol
- Document IRB notification in system
- Follow up until resolved

### Compliance

**Good Clinical Practice (GCP):**
- Enter data as soon as possible after observation
- Don't backdate entries
- If you need to correct data, add note explaining why
- Never delete data - mark as incorrect and add correction

**Audit Trail:**
- Every action is logged (who, what, when)
- Changes are tracked
- Exports are recorded
- You cannot erase the audit trail

## Common Tasks

### Task: Record Vital Signs

1. Select study and participant
2. Go to Data Entry > Observation
3. Observation Type = "Vital Signs"
4. For each vital sign:
   - Blood Pressure: "Systolic Blood Pressure", value, "mmHg"
   - Heart Rate: "Heart Rate", value, "bpm"
   - Temperature: "Temperature", value, "°C"
5. Or enter as separate observations
6. Save

### Task: Document an Adverse Event

1. Go to Data Entry > Finding
2. Select participant
3. Finding Type = "Adverse Event"
4. Describe the event in detail
5. Select severity
6. Select relationship to study intervention
7. Document action taken
8. If SAE: Check SAE box, report to IRB
9. Save

### Task: Weekly Progress Note

1. Go to Data Entry > Quick Note
2. Note Type = "Progress Note"
3. Title = "Week [X] Progress - [Date]"
4. Document:
   - Enrollment updates
   - Any issues encountered
   - Upcoming activities
   - Observations
5. Add tags: "progress", "week-[X]"
6. Save

### Task: Export Study Data for Analysis

1. Go to Import/Export > Export to Excel
2. Select "Current Study Only"
3. Check all data types you need
4. Include metadata if doing analysis
5. Generate export
6. Download CSV
7. Import into your analysis tool (R, Python, SPSS, etc.)

### Task: Search for Previous Notes

1. Go to Search > Search Notes
2. Enter keywords (e.g., "headache", "protocol deviation")
3. Optionally filter by note type and date
4. Click Search
5. Results show matching notes

## Troubleshooting

### Can't See My Study

**Reason**: You may not have access to that study

**Solution**:
- Contact PI or Data Manager
- They can grant you access via Admin page
- Or contact system administrator

### Can't Save Data

**Possible reasons:**
- Required fields not filled in
- Date validation failed (future date?)
- Participant not enrolled yet
- Study is not selected

**Solution:**
- Check for error message
- Ensure all required fields (*) are filled
- Check sidebar for selected study
- Refresh page and try again

### Data Doesn't Appear After Saving

**Reason**: May be a display refresh issue

**Solution:**
- Navigate to different page and back
- Or refresh browser
- Data is saved even if not immediately visible

### Import Fails

**Common causes:**
- Incorrect column mapping
- Invalid data format
- Dates not in YYYY-MM-DD format
- Required fields missing in spreadsheet

**Solution:**
- Check spreadsheet format
- Ensure all required columns present
- Format dates as YYYY-MM-DD
- Remove any special characters

## Tips & Tricks

### Keyboard Shortcuts
- **Tab**: Move to next field
- **Shift+Tab**: Move to previous field
- **Ctrl+Enter**: Submit form (in most browsers)

### Efficient Data Entry
1. **Prepare participant list** in advance
2. **Batch similar observations** (do all vital signs at once)
3. **Use copy-paste** for repetitive text
4. **Save frequently** (don't lose work)

### Better Searching
- Use **specific keywords** (not general terms)
- Add **tags** to your notes for easier retrieval
- Use **date filters** to narrow results
- **Save common searches** (coming soon)

### Collaboration
- **@mention** people in notes (feature coming)
- **Flag items** for review so others see them
- **Add comments** on findings for discussion
- **Check recent activity** to see what others have done

## Getting Help

### In-App Help
- **? icons**: Hover over for field-specific help
- **Info boxes**: Blue boxes with tips and guidance

### Documentation
- **User Guide**: This document
- **Admin Guide**: For system administrators
- **Data Dictionary**: Database schema reference

### Support
- **Email**: research.support@example.org
- **Response Time**: Within 1 business day
- **For urgent issues** (system down): Call IT help desk

### Training
- **Video tutorials**: Available in app (coming soon)
- **Office hours**: Weekly Q&A sessions
- **One-on-one training**: Available on request

## Appendix: Field Definitions

### Study Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| Study Name | Descriptive study title | Yes | "Hypertension Treatment Study 2024" |
| Protocol Number | IRB or protocol number | Yes | "IRB-2024-001" |
| Principal Investigator | Lead researcher name | Yes | "Dr. Jane Smith" |
| Study Type | Type of research | Yes | "Randomized Controlled Trial" |
| Study Phase | Current phase | Yes | "Active" |
| Target Enrollment | Planned participants | Yes | 100 |

### Participant Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| Participant Number | Study-specific ID | Yes | "001" |
| Enrollment Date | Date enrolled | Yes | "2024-10-15" |
| Consent Date | Date consent obtained | Yes | "2024-10-15" |
| Demographic Group | De-identified category | No | "Adult Female 40-50" |

### Observation Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| Observation Date | When observed | Yes | "2024-10-15" |
| Visit Number | Visit sequence | Yes | 1 |
| Observation Type | Type of observation | Yes | "Vital Signs" |
| Measurement Name | What was measured | Yes | "Systolic BP" |
| Value | Measurement value | Yes | "125" |
| Unit | Unit of measure | No | "mmHg" |

### Note Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| Note Type | Type of note | Yes | "Progress Note" |
| Note Title | Brief summary | Yes | "Week 4 Visit" |
| Note Content | Detailed notes | Yes | "Patient reported..." |
| Priority | Urgency level | No | "Normal" |

### Finding Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| Finding Type | Type of finding | Yes | "Adverse Event" |
| Description | Detailed description | Yes | "Patient experienced headache..." |
| Severity | Severity level | Yes | "Mild" |
| Relationship | Relation to treatment | Yes (for AEs) | "Possibly Related" |
| Outcome | Current outcome | Yes | "Resolved" |

## Frequently Asked Questions

### Q: Can I still use Excel?

**A:** Yes, for analysis! But use this system for data entry and primary storage. You can export to Excel anytime.

### Q: What happens to my old spreadsheets?

**A:** Keep them as archives. Import the data into this system using the Import feature, then retire the spreadsheets.

### Q: Can multiple people enter data simultaneously?

**A:** Yes! That's one of the big advantages. Multiple researchers can work on different participants or studies at the same time.

### Q: Is my data backed up?

**A:** Yes, automatically. Snowflake provides automatic backup and 90-day time travel for recovery.

### Q: Can I delete a mistake?

**A:** No deletion (for compliance), but you can add a note explaining the error and enter the correct data. Contact Data Manager for data corrections.

### Q: How do I know if I entered data correctly?

**A:** The system validates data in real-time. You'll see warnings for unusual values. Data Managers periodically review and verify data.

### Q: Can I access the system from home?

**A:** Yes, if you have VPN access to Snowflake. Check with your IT department about remote access policies.

### Q: Is this HIPAA compliant?

**A:** Yes, when used correctly. Don't enter actual patient names or direct identifiers. Use study participant numbers only.

### Q: Can I customize the forms?

**A:** Contact the system administrator. Custom fields can be added to the metadata fields.

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-23  
**For questions:** research.support@example.org

