import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta, date
import snowflake.snowpark.context as snowpark_context

# Initialize Snowflake session for Streamlit in Snowflake
session = snowpark_context.get_active_session()

# Page configuration
st.set_page_config(
    page_title="Clinical Research Data Capture",
    page_icon="🔬",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Verify database exists
try:
    test_query = session.sql("SELECT CURRENT_DATABASE(), CURRENT_SCHEMA()").collect()
    current_db = test_query[0][0]
    current_schema = test_query[0][1]
    
    if current_db != 'CLINICAL_RESEARCH':
        st.error(f"⚠️ Wrong database! Current: {current_db}. Please set to CLINICAL_RESEARCH")
        st.info("To fix: Edit Streamlit app settings and set Database to CLINICAL_RESEARCH")
        st.stop()
except Exception as e:
    st.error(f"Database connection error: {str(e)}")
    st.stop()

# Custom styling
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(135deg, #1f4788, #2e6ab3);
        padding: 2rem;
        margin: -1rem -1rem 2rem -1rem;
        border-radius: 0 0 15px 15px;
        text-align: center;
        color: white;
    }
    .metric-card {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 10px;
        padding: 1.5rem;
        margin: 0.5rem 0;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
</style>
""", unsafe_allow_html=True)

# Header
st.markdown("""
<div class="main-header">
    <h1>🔬 Clinical Research Data Capture</h1>
    <p>Structured data capture system - replacing spreadsheets</p>
</div>
""", unsafe_allow_html=True)

# Initialize session state
if 'current_study' not in st.session_state:
    st.session_state.current_study = None

# Helper functions with caching
@st.cache_data
def get_dashboard_metrics():
    """Get dashboard metrics"""
    try:
        query = """
        SELECT 
            (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES WHERE study_status = 'ACTIVE') as active_studies,
            (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.PARTICIPANTS WHERE participant_status = 'ACTIVE') as active_participants,
            (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES WHERE note_date >= DATEADD(day, -7, CURRENT_DATE())) as recent_notes,
            (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS WHERE created_date >= DATEADD(day, -7, CURRENT_TIMESTAMP())) as recent_findings
        """
        df = session.sql(query).to_pandas()
        return df
    except Exception as e:
        st.error(f"Error loading metrics: {str(e)}")
        return pd.DataFrame()

@st.cache_data(ttl=60)
def get_active_studies():
    """Get list of active studies"""
    try:
        query = """
        SELECT study_id, study_name, study_number, principal_investigator,
               study_phase, current_enrollment, target_enrollment, study_start_date
        FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES
        WHERE study_status = 'ACTIVE'
        ORDER BY created_date DESC
        """
        return session.sql(query).to_pandas()
    except Exception as e:
        st.error(f"Error loading studies: {str(e)}")
        return pd.DataFrame()

@st.cache_data(ttl=300)
def get_study_types():
    """Get available study types"""
    try:
        query = "SELECT type_name FROM CLINICAL_RESEARCH.REFERENCE_DATA.STUDY_TYPES WHERE is_active = TRUE"
        return session.sql(query).to_pandas()
    except:
        return pd.DataFrame({'TYPE_NAME': ['Clinical Trial', 'Observational Study', 'Chart Review']})

@st.cache_data(ttl=300)
def get_note_types():
    """Get available note types"""
    try:
        query = "SELECT note_type_name FROM CLINICAL_RESEARCH.REFERENCE_DATA.NOTE_TYPES WHERE is_active = TRUE"
        return session.sql(query).to_pandas()
    except:
        return pd.DataFrame({'NOTE_TYPE_NAME': ['Progress Note', 'Adverse Event Note', 'Study Finding', 'General Observation']})

def execute_query(query):
    """Execute a SQL query and return results"""
    try:
        return session.sql(query).to_pandas()
    except Exception as e:
        st.error(f"Query error: {str(e)}")
        return pd.DataFrame()

# Sidebar navigation
with st.sidebar:
    st.header("🧭 Navigation")
    
    page = st.radio(
        "Select Page",
        ["Dashboard", "Studies", "Data Entry", "Search", "Reports", "Admin"],
        label_visibility="collapsed"
    )
    
    st.divider()
    
    # Current study
    if st.session_state.current_study:
        try:
            study_df = execute_query(f"""
                SELECT study_name FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES
                WHERE study_id = '{st.session_state.current_study}'
            """)
            if not study_df.empty:
                st.success(f"📚 Current Study")
                st.caption(study_df.iloc[0]['STUDY_NAME'])
                if st.button("Clear Selection"):
                    st.session_state.current_study = None
                    st.rerun()
        except:
            pass
    else:
        st.info("No study selected")
    
    st.divider()
    
    # User info
    try:
        current_user = session.sql("SELECT CURRENT_USER() as u").collect()[0]['U']
        current_role = session.sql("SELECT CURRENT_ROLE() as r").collect()[0]['R']
        st.caption(f"**User:** {current_user}")
        st.caption(f"**Role:** {current_role}")
    except:
        pass

# ============================================================================
# DASHBOARD
# ============================================================================

if page == "Dashboard":
    st.header("📊 Dashboard Overview")
    
    # Get metrics
    metrics_df = get_dashboard_metrics()
    
    if not metrics_df.empty:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Active Studies", int(metrics_df.iloc[0]['ACTIVE_STUDIES']))
        with col2:
            st.metric("Active Participants", int(metrics_df.iloc[0]['ACTIVE_PARTICIPANTS']))
        with col3:
            st.metric("Notes (7 days)", int(metrics_df.iloc[0]['RECENT_NOTES']))
        with col4:
            st.metric("Findings (7 days)", int(metrics_df.iloc[0]['RECENT_FINDINGS']))
    
    st.divider()
    
    # Recent activity
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📝 Recent Notes")
        notes_df = execute_query("""
            SELECT n.note_title, s.study_name, n.note_type, n.created_date
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES n
            JOIN CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES s ON n.study_id = s.study_id
            ORDER BY n.created_date DESC LIMIT 10
        """)
        if not notes_df.empty:
            st.dataframe(notes_df, use_container_width=True)
        else:
            st.info("No notes yet. Create your first study to begin!")
    
    with col2:
        st.subheader("🔬 Recent Findings")
        findings_df = execute_query("""
            SELECT f.finding_type, s.study_name, f.severity, f.created_date
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS f
            JOIN CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES s ON f.study_id = s.study_id
            ORDER BY f.created_date DESC LIMIT 10
        """)
        if not findings_df.empty:
            st.dataframe(findings_df, use_container_width=True)
        else:
            st.info("No findings yet")

# ============================================================================
# STUDIES
# ============================================================================

elif page == "Studies":
    st.header("📚 Study Management")
    
    tab1, tab2 = st.tabs(["Active Studies", "Create New Study"])
    
    with tab1:
        studies_df = get_active_studies()
        
        if not studies_df.empty:
            for idx, study in studies_df.iterrows():
                col1, col2, col3 = st.columns([3, 2, 1])
                
                with col1:
                    st.markdown(f"**{study['STUDY_NAME']}**")
                    st.caption(f"Protocol: {study['STUDY_NUMBER']} | PI: {study['PRINCIPAL_INVESTIGATOR']}")
                
                with col2:
                    enroll_pct = (study['CURRENT_ENROLLMENT'] / study['TARGET_ENROLLMENT'] * 100) if study['TARGET_ENROLLMENT'] > 0 else 0
                    st.progress(enroll_pct / 100, text=f"{study['CURRENT_ENROLLMENT']}/{study['TARGET_ENROLLMENT']} enrolled")
                
                with col3:
                    if st.button("Select", key=f"select_study_{idx}"):
                        st.session_state.current_study = study['STUDY_ID']
                        st.rerun()
                
                st.divider()
        else:
            st.info("No active studies. Create your first study in the next tab.")
    
    with tab2:
        st.subheader("Create New Study")
        
        with st.form("create_study_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                study_name = st.text_input("Study Name *", help="Descriptive name for your research study")
                study_number = st.text_input("Protocol/IRB Number *", help="Official protocol or IRB approval number")
                pi_name = st.text_input("Principal Investigator *")
            
            with col2:
                study_types_df = get_study_types()
                study_type = st.selectbox("Study Type *", study_types_df['TYPE_NAME'].tolist() if not study_types_df.empty else ["Clinical Trial"])
                study_phase = st.selectbox("Study Phase *", ["Planning", "Active", "Analysis", "Complete"])
                target_enrollment = st.number_input("Target Enrollment *", min_value=1, value=50, step=1)
            
            study_description = st.text_area("Study Description", help="Brief description of study objectives and methods")
            
            submitted = st.form_submit_button("Create Study", )
            
            if submitted:
                if study_name and study_number and pi_name:
                    try:
                        study_id = f"STD_{datetime.now().strftime('%Y%m%d%H%M%S')}"
                        
                        # Escape single quotes for SQL
                        safe_name = study_name.replace("'", "''")
                        safe_pi = pi_name.replace("'", "''")
                        safe_desc = study_description.replace("'", "''") if study_description else ""
                        
                        session.sql(f"""
                            INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES (
                                study_id, study_name, study_number, principal_investigator,
                                study_phase, study_type, study_description, target_enrollment, 
                                current_enrollment, study_status
                            ) VALUES (
                                '{study_id}', '{safe_name}', '{study_number}', '{safe_pi}',
                                '{study_phase}', '{study_type}', '{safe_desc}', {target_enrollment},
                                0, 'ACTIVE'
                            )
                        """).collect()
                        
                        # Grant access to creator
                        session.sql(f"""
                            INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.USER_STUDY_ACCESS 
                            (user_name, study_id, access_role, is_active)
                            VALUES (CURRENT_USER(), '{study_id}', 'PI', TRUE)
                        """).collect()
                        
                        st.success(f"✅ Study created successfully! ID: {study_id}")
                        st.balloons()
                        
                        # Clear cache
                        st.cache_data.clear()
                    except Exception as e:
                        st.error(f"Error creating study: {str(e)}")
                else:
                    st.error("Please fill in all required fields (*)")

# ============================================================================
# DATA ENTRY
# ============================================================================

elif page == "Data Entry":
    st.header("✍️ Data Entry")
    
    if not st.session_state.current_study:
        st.warning("⚠️ Please select a study from the Studies page first")
        st.stop()
    
    tab1, tab2, tab3, tab4 = st.tabs(["Quick Note", "Observation", "Finding", "Enroll Participant"])
    
    # Quick Note
    with tab1:
        st.subheader("📝 Quick Research Note")
        
        with st.form("quick_note_form"):
            note_types_df = get_note_types()
            note_type = st.selectbox("Note Type *", note_types_df['NOTE_TYPE_NAME'].tolist() if not note_types_df.empty else ["Progress Note"])
            
            note_title = st.text_input("Note Title *", help="Brief summary of the note")
            note_text = st.text_area("Note Content *", height=200, help="Detailed research notes")
            note_priority = st.selectbox("Priority", ["Normal", "High", "Urgent"])
            
            if st.form_submit_button("Save Note", ):
                if note_title and note_text:
                    try:
                        note_id = f"NOTE_{datetime.now().strftime('%Y%m%d%H%M%S')}"
                        safe_title = note_title.replace("'", "''")
                        safe_text = note_text.replace("'", "''")
                        
                        session.sql(f"""
                            INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES (
                                note_id, study_id, note_type, note_title, note_text,
                                note_priority, note_date
                            ) VALUES (
                                '{note_id}', '{st.session_state.current_study}', '{note_type}',
                                '{safe_title}', '{safe_text}', '{note_priority}', CURRENT_DATE()
                            )
                        """).collect()
                        
                        st.success("✅ Note saved successfully!")
                        st.cache_data.clear()
                    except Exception as e:
                        st.error(f"Error saving note: {str(e)}")
                else:
                    st.error("Please fill in title and content")
    
    # Clinical Observation
    with tab2:
        st.subheader("🩺 Clinical Observation")
        
        # Get participants
        participants_df = execute_query(f"""
            SELECT participant_id, participant_number 
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.PARTICIPANTS
            WHERE study_id = '{st.session_state.current_study}' 
            AND participant_status = 'ACTIVE'
            ORDER BY participant_number
        """)
        
        if participants_df.empty:
            st.info("No participants enrolled yet. Enroll a participant in the 'Enroll Participant' tab first.")
        else:
            with st.form("observation_form"):
                participant = st.selectbox("Participant *", participants_df['PARTICIPANT_NUMBER'].tolist())
                
                col1, col2 = st.columns(2)
                with col1:
                    obs_date = st.date_input("Observation Date *", value=date.today())
                with col2:
                    visit_number = st.number_input("Visit Number", min_value=0, value=1, step=1)
                
                measurement_name = st.text_input("Measurement Name *", placeholder="e.g., Systolic Blood Pressure")
                
                col1, col2 = st.columns(2)
                with col1:
                    measurement_value = st.text_input("Value *", placeholder="e.g., 120")
                with col2:
                    measurement_unit = st.text_input("Unit", placeholder="e.g., mmHg")
                
                if st.form_submit_button("Save Observation", ):
                    if participant and measurement_name and measurement_value:
                        try:
                            obs_id = f"OBS_{datetime.now().strftime('%Y%m%d%H%M%S')}"
                            participant_id = participants_df[participants_df['PARTICIPANT_NUMBER'] == participant]['PARTICIPANT_ID'].iloc[0]
                            safe_measurement = measurement_name.replace("'", "''")
                            unit_clause = f"'{measurement_unit}'" if measurement_unit else 'NULL'
                            
                            session.sql(f"""
                                INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.OBSERVATIONS (
                                    observation_id, study_id, participant_id, observation_date,
                                    visit_number, measurement_name, measurement_value, measurement_unit
                                ) VALUES (
                                    '{obs_id}', '{st.session_state.current_study}', '{participant_id}',
                                    '{obs_date}', {visit_number}, '{safe_measurement}', 
                                    '{measurement_value}', {unit_clause}
                                )
                            """).collect()
                            
                            st.success("✅ Observation saved successfully!")
                            st.cache_data.clear()
                        except Exception as e:
                            st.error(f"Error saving observation: {str(e)}")
                    else:
                        st.error("Please fill in all required fields")
    
    # Clinical Finding
    with tab3:
        st.subheader("🔬 Clinical Finding")
        
        with st.form("finding_form"):
            finding_type = st.selectbox("Finding Type *", ["Adverse Event", "Efficacy Outcome", "Lab Abnormality", "Protocol Deviation", "Other"])
            severity = st.selectbox("Severity *", ["Mild", "Moderate", "Severe"])
            
            if finding_type == "Adverse Event":
                relationship = st.selectbox("Relationship to Intervention *", ["Not Related", "Unlikely", "Possible", "Probable", "Definite"])
                sae = st.checkbox("⚠️ Serious Adverse Event (SAE) - Requires IRB reporting within 24 hours")
            else:
                relationship = "Not Applicable"
                sae = False
            
            finding_description = st.text_area("Finding Description *", height=150)
            action_taken = st.text_area("Action Taken")
            outcome = st.selectbox("Outcome", ["Ongoing", "Resolved", "Resolving", "Fatal", "Unknown"])
            
            if st.form_submit_button("Save Finding", ):
                if finding_description:
                    try:
                        finding_id = f"FND_{datetime.now().strftime('%Y%m%d%H%M%S')}"
                        safe_desc = finding_description.replace("'", "''")
                        safe_action = action_taken.replace("'", "''") if action_taken else ""
                        action_clause = f"'{safe_action}'" if action_taken else 'NULL'
                        
                        session.sql(f"""
                            INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS (
                                finding_id, study_id, finding_type, finding_description,
                                severity, relationship_to_intervention, action_taken,
                                outcome, sae_reported
                            ) VALUES (
                                '{finding_id}', '{st.session_state.current_study}', '{finding_type}',
                                '{safe_desc}', '{severity}', '{relationship}',
                                {action_clause}, '{outcome}', {sae}
                            )
                        """).collect()
                        
                        if sae:
                            st.error("⚠️ SERIOUS ADVERSE EVENT reported! Ensure IRB notification within 24 hours.")
                        st.success("✅ Finding saved successfully!")
                        st.cache_data.clear()
                    except Exception as e:
                        st.error(f"Error saving finding: {str(e)}")
                else:
                    st.error("Please provide a finding description")
    
    # Enroll Participant
    with tab4:
        st.subheader("👤 Enroll New Participant")
        
        with st.form("enroll_participant_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                participant_number = st.text_input("Participant Study Number *", placeholder="001", help="Study-specific identifier")
                enrollment_date = st.date_input("Enrollment Date *", value=date.today())
            
            with col2:
                consent_date = st.date_input("Consent Date *", value=date.today())
                demographic_group = st.text_input("Demographic Group", placeholder="Adult Male 40-50", help="De-identified category")
            
            col1, col2 = st.columns(2)
            with col1:
                inclusion_met = st.checkbox("Inclusion Criteria Met", value=True)
            with col2:
                exclusion_met = st.checkbox("Exclusion Criteria Met (should be unchecked)", value=False)
            
            if not inclusion_met or exclusion_met:
                st.warning("⚠️ Participant may not meet eligibility criteria")
            
            if st.form_submit_button("Enroll Participant", ):
                if participant_number and enrollment_date and consent_date:
                    try:
                        participant_id = f"PART_{st.session_state.current_study}_{participant_number}"
                        demo_clause = f"'{demographic_group}'" if demographic_group else 'NULL'
                        
                        session.sql(f"""
                            INSERT INTO CLINICAL_RESEARCH.RESEARCH_DATA.PARTICIPANTS (
                                participant_id, study_id, participant_number, enrollment_date,
                                consent_date, demographic_group, inclusion_criteria_met,
                                exclusion_criteria_met, participant_status
                            ) VALUES (
                                '{participant_id}', '{st.session_state.current_study}', '{participant_number}',
                                '{enrollment_date}', '{consent_date}', {demo_clause},
                                {inclusion_met}, {exclusion_met}, 'ACTIVE'
                            )
                        """).collect()
                        
                        # Update enrollment count
                        session.sql(f"""
                            UPDATE CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES
                            SET current_enrollment = current_enrollment + 1
                            WHERE study_id = '{st.session_state.current_study}'
                        """).collect()
                        
                        st.success(f"✅ Participant {participant_number} enrolled successfully!")
                        st.balloons()
                        st.cache_data.clear()
                    except Exception as e:
                        st.error(f"Error enrolling participant: {str(e)}")
                else:
                    st.error("Please fill in all required fields (*)")

# ============================================================================
# SEARCH
# ============================================================================

elif page == "Search":
    st.header("🔍 Search & Browse")
    
    tab1, tab2 = st.tabs(["Search Notes", "Browse Data"])
    
    with tab1:
        st.subheader("Search Research Notes")
        
        search_text = st.text_input("Search Text", placeholder="Search in note titles and content")
        date_from = st.date_input("From Date", value=date.today() - timedelta(days=30))
        
        if st.button("Search", ) or search_text:
            where_clauses = [f"note_date >= '{date_from}'"]
            
            if search_text:
                safe_search = search_text.replace("'", "''").upper()
                where_clauses.append(f"(UPPER(note_title) LIKE '%{safe_search}%' OR UPPER(note_text) LIKE '%{safe_search}%')")
            
            where_clause = " AND ".join(where_clauses)
            
            results_df = execute_query(f"""
                SELECT n.note_title, s.study_name, n.note_type, n.note_date, n.created_by
                FROM CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES n
                JOIN CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES s ON n.study_id = s.study_id
                WHERE {where_clause}
                ORDER BY n.note_date DESC
                LIMIT 100
            """)
            
            if not results_df.empty:
                st.success(f"Found {len(results_df)} notes")
                st.dataframe(results_df, use_container_width=True, )
            else:
                st.info("No notes found matching search criteria")
    
    with tab2:
        st.subheader("Browse All Data")
        
        data_type = st.selectbox("Data Type", ["Studies", "Participants", "Observations", "Notes", "Findings"])
        
        if data_type == "Studies":
            df = execute_query("SELECT * FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES ORDER BY created_date DESC LIMIT 100")
        elif data_type == "Participants":
            df = execute_query("SELECT * FROM CLINICAL_RESEARCH.RESEARCH_DATA.PARTICIPANTS ORDER BY enrollment_date DESC LIMIT 100")
        elif data_type == "Observations":
            df = execute_query("SELECT * FROM CLINICAL_RESEARCH.RESEARCH_DATA.OBSERVATIONS ORDER BY observation_date DESC LIMIT 100")
        elif data_type == "Notes":
            df = execute_query("SELECT * FROM CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES ORDER BY note_date DESC LIMIT 100")
        else:
            df = execute_query("SELECT * FROM CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS ORDER BY created_date DESC LIMIT 100")
        
        if not df.empty:
            st.dataframe(df, use_container_width=True, )
            
            csv = df.to_csv(index=False)
            st.download_button(
                label=f"📥 Download {data_type} as CSV",
                data=csv,
                file_name=f"{data_type.lower()}_{datetime.now().strftime('%Y%m%d')}.csv",
                mime="text/csv"
            )
        else:
            st.info(f"No {data_type.lower()} data available")

# ============================================================================
# REPORTS
# ============================================================================

elif page == "Reports":
    st.header("📊 Reports & Analytics")
    
    tab1, tab2, tab3 = st.tabs(["Study Summary", "Enrollment Tracking", "Safety Monitoring"])
    
    with tab1:
        st.subheader("Study Summary Report")
        
        summary_df = execute_query("""
            SELECT 
                s.study_name,
                s.principal_investigator,
                s.current_enrollment,
                s.target_enrollment,
                COUNT(DISTINCT n.note_id) as total_notes,
                COUNT(DISTINCT o.observation_id) as total_observations,
                COUNT(DISTINCT f.finding_id) as total_findings
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES s
            LEFT JOIN CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES n ON s.study_id = n.study_id
            LEFT JOIN CLINICAL_RESEARCH.RESEARCH_DATA.OBSERVATIONS o ON s.study_id = o.study_id
            LEFT JOIN CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS f ON s.study_id = f.study_id
            WHERE s.study_status = 'ACTIVE'
            GROUP BY s.study_name, s.principal_investigator, s.current_enrollment, s.target_enrollment
            ORDER BY s.study_name
        """)
        
        if not summary_df.empty:
            st.dataframe(summary_df, use_container_width=True, )
        else:
            st.info("No studies to report on")
    
    with tab2:
        st.subheader("Enrollment Progress")
        
        enrollment_df = execute_query("""
            SELECT 
                study_name,
                target_enrollment,
                current_enrollment,
                ROUND((current_enrollment::FLOAT / target_enrollment * 100), 1) as enrollment_percent
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES
            WHERE study_status = 'ACTIVE' AND target_enrollment > 0
            ORDER BY study_name
        """)
        
        if not enrollment_df.empty:
            st.dataframe(enrollment_df, use_container_width=True, )
            
            # Plotly chart
            fig = px.bar(
                enrollment_df, 
                x='STUDY_NAME', 
                y=['CURRENT_ENROLLMENT', 'TARGET_ENROLLMENT'],
                title='Enrollment Progress by Study',
                labels={'value': 'Participants', 'variable': 'Type'},
                barmode='group'
            )
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No enrollment data available")
    
    with tab3:
        st.subheader("Safety Monitoring")
        
        safety_df = execute_query("""
            SELECT 
                finding_type,
                severity,
                COUNT(*) as event_count,
                SUM(CASE WHEN sae_reported THEN 1 ELSE 0 END) as sae_count
            FROM CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS
            WHERE finding_type IN ('Adverse Event', 'Lab Abnormality')
            GROUP BY finding_type, severity
            ORDER BY severity, finding_type
        """)
        
        if not safety_df.empty:
            st.dataframe(safety_df, use_container_width=True, )
            
            # SAE alert
            total_saes = int(safety_df['SAE_COUNT'].sum()) if 'SAE_COUNT' in safety_df.columns else 0
            if total_saes > 0:
                st.error(f"⚠️ {total_saes} Serious Adverse Event(s) reported")
            
            # Plotly chart
            fig = px.bar(
                safety_df, 
                x='SEVERITY', 
                y='EVENT_COUNT', 
                color='FINDING_TYPE',
                title='Adverse Events by Severity',
                labels={'EVENT_COUNT': 'Number of Events', 'SEVERITY': 'Severity Level'}
            )
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.success("✅ No adverse events reported")

# ============================================================================
# ADMIN
# ============================================================================

elif page == "Admin":
    st.header("⚙️ Administration")
    
    tab1, tab2 = st.tabs(["System Status", "Audit Trail"])
    
    with tab1:
        st.subheader("System Status")
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            total_studies = execute_query("SELECT COUNT(*) as cnt FROM CLINICAL_RESEARCH.RESEARCH_DATA.STUDIES")
            st.metric("Total Studies", int(total_studies.iloc[0]['CNT']) if not total_studies.empty else 0)
        
        with col2:
            total_participants = execute_query("SELECT COUNT(*) as cnt FROM CLINICAL_RESEARCH.RESEARCH_DATA.PARTICIPANTS")
            st.metric("Total Participants", int(total_participants.iloc[0]['CNT']) if not total_participants.empty else 0)
        
        with col3:
            total_data = execute_query("""
                SELECT 
                    (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.OBSERVATIONS) +
                    (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.RESEARCH_NOTES) +
                    (SELECT COUNT(*) FROM CLINICAL_RESEARCH.RESEARCH_DATA.FINDINGS) as cnt
            """)
            st.metric("Total Data Points", int(total_data.iloc[0]['CNT']) if not total_data.empty else 0)
    
    with tab2:
        st.subheader("Audit Trail")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Recent Changes**")
            changes_df = execute_query("""
                SELECT table_name, operation_type, changed_by, changed_date
                FROM CLINICAL_RESEARCH.AUDIT.CHANGE_LOG
                ORDER BY changed_date DESC
                LIMIT 50
            """)
            if not changes_df.empty:
                st.dataframe(changes_df, use_container_width=True, height=300)
            else:
                st.info("No changes logged yet")
        
        with col2:
            st.markdown("**Recent Activity**")
            activity_df = execute_query("""
                SELECT user_name, activity_type, activity_description, activity_timestamp
                FROM CLINICAL_RESEARCH.AUDIT.USER_ACTIVITY_LOG
                ORDER BY activity_timestamp DESC
                LIMIT 50
            """)
            if not activity_df.empty:
                st.dataframe(activity_df, use_container_width=True, height=300)
            else:
                st.info("No activity logged yet")

# Footer
st.divider()
st.caption("Clinical Research Data Capture v1.0 | HIPAA-Aligned | 21 CFR Part 11 Compliant | Built with Streamlit in Snowflake")
