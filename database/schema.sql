-- =============================================================
-- Envico CareOS 2026 — Core Database Schema
-- PostgreSQL / Supabase
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================
-- USERS (system accounts — staff, managers, admins)
-- =============================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'care_worker', -- admin, manager, care_worker, finance, compliance
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- REFERRALS
-- =============================================================
CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_number VARCHAR(50) UNIQUE NOT NULL,
    referrer_name VARCHAR(255) NOT NULL,
    referrer_organisation VARCHAR(255),
    referrer_email VARCHAR(255),
    referrer_phone VARCHAR(50),
    client_name VARCHAR(255) NOT NULL,
    client_dob DATE,
    client_nhs_number VARCHAR(20),
    care_type VARCHAR(100) NOT NULL, -- supported_living, domiciliary, residential
    support_hours_per_week NUMERIC(6,2),
    funding_source VARCHAR(100), -- local_authority, self_funded, nhs, mixed
    urgency VARCHAR(20) NOT NULL DEFAULT 'standard', -- emergency, urgent, standard
    status VARCHAR(50) NOT NULL DEFAULT 'received', -- received, under_review, assessment_booked, accepted, declined, waitlist
    assigned_to UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- SERVICE USERS
-- =============================================================
CREATE TABLE service_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID REFERENCES referrals(id),
    reference_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    preferred_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(50),
    nhs_number VARCHAR(20),
    address TEXT,
    postcode VARCHAR(20),
    phone VARCHAR(50),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    emergency_contact_relationship VARCHAR(100),
    care_type VARCHAR(100) NOT NULL,
    funding_source VARCHAR(100),
    local_authority VARCHAR(255),
    care_manager_name VARCHAR(255),
    care_manager_email VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, suspended, discharged, deceased
    start_date DATE,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- STAFF
-- =============================================================
CREATE TABLE staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    employee_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(50),
    phone VARCHAR(50),
    email VARCHAR(255) UNIQUE NOT NULL,
    address TEXT,
    postcode VARCHAR(20),
    role VARCHAR(100) NOT NULL, -- care_worker, senior_care_worker, team_leader, manager, coordinator
    contract_type VARCHAR(50) NOT NULL DEFAULT 'permanent', -- permanent, zero_hours, agency, bank
    contracted_hours NUMERIC(5,2),
    hourly_rate NUMERIC(8,2),
    start_date DATE NOT NULL,
    end_date DATE,
    dbs_number VARCHAR(50),
    dbs_issue_date DATE,
    dbs_expiry_date DATE,
    right_to_work_expiry DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, suspended, resigned, terminated
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- SHIFTS
-- =============================================================
CREATE TABLE shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_date DATE NOT NULL,
    shift_type VARCHAR(50) NOT NULL, -- morning, afternoon, evening, night, waking_night, sleep_in
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location VARCHAR(255),
    service_user_id UUID REFERENCES service_users(id),
    required_staff_count INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, filled, partially_filled, cancelled
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- SHIFT ASSIGNMENTS
-- =============================================================
CREATE TABLE shift_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES staff(id),
    status VARCHAR(50) NOT NULL DEFAULT 'assigned', -- assigned, confirmed, completed, no_show, swapped, cancelled
    clock_in TIMESTAMPTZ,
    clock_out TIMESTAMPTZ,
    actual_hours NUMERIC(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(shift_id, staff_id)
);

-- =============================================================
-- MEDICATIONS
-- =============================================================
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_user_id UUID NOT NULL REFERENCES service_users(id),
    medication_name VARCHAR(255) NOT NULL,
    generic_name VARCHAR(255),
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    route VARCHAR(100) NOT NULL, -- oral, topical, inhaled, injection, patch
    prescriber VARCHAR(255),
    pharmacy VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    repeat_prescription BOOLEAN NOT NULL DEFAULT FALSE,
    controlled_drug BOOLEAN NOT NULL DEFAULT FALSE,
    storage_instructions TEXT,
    side_effects TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, discontinued, suspended, completed
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- MEDICATION LOGS (MAR — Medication Administration Records)
-- =============================================================
CREATE TABLE medication_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID NOT NULL REFERENCES medications(id),
    service_user_id UUID NOT NULL REFERENCES service_users(id),
    administered_by UUID NOT NULL REFERENCES staff(id),
    scheduled_time TIMESTAMPTZ NOT NULL,
    administered_time TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, administered, refused, missed, not_required
    refusal_reason TEXT,
    notes TEXT,
    witnessed_by UUID REFERENCES staff(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- INCIDENTS
-- =============================================================
CREATE TABLE incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_number VARCHAR(50) UNIQUE NOT NULL,
    incident_date TIMESTAMPTZ NOT NULL,
    location VARCHAR(255),
    service_user_id UUID REFERENCES service_users(id),
    reported_by UUID NOT NULL REFERENCES staff(id),
    incident_type VARCHAR(100) NOT NULL, -- fall, medication_error, challenging_behaviour, property_damage, near_miss, other
    severity VARCHAR(50) NOT NULL DEFAULT 'low', -- low, medium, high, critical
    description TEXT NOT NULL,
    immediate_action_taken TEXT,
    injuries_sustained BOOLEAN NOT NULL DEFAULT FALSE,
    injury_description TEXT,
    witness_names TEXT,
    notified_parties TEXT, -- manager, family, GP, CQC, police, local_authority
    riddor_reportable BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, under_investigation, closed, escalated
    investigated_by UUID REFERENCES users(id),
    investigation_notes TEXT,
    outcome TEXT,
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- SAFEGUARDING REPORTS
-- =============================================================
CREATE TABLE safeguarding_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_number VARCHAR(50) UNIQUE NOT NULL,
    report_date TIMESTAMPTZ NOT NULL,
    service_user_id UUID REFERENCES service_users(id),
    reported_by UUID NOT NULL REFERENCES staff(id),
    category VARCHAR(100) NOT NULL, -- physical, emotional, sexual, financial, neglect, discriminatory, institutional, self_neglect
    description TEXT NOT NULL,
    alleged_perpetrator VARCHAR(255),
    perpetrator_relationship VARCHAR(100),
    referral_to_safeguarding_team BOOLEAN NOT NULL DEFAULT FALSE,
    referral_date DATE,
    local_authority_ref VARCHAR(100),
    police_notified BOOLEAN NOT NULL DEFAULT FALSE,
    police_ref VARCHAR(100),
    cqc_notified BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, referred, under_investigation, closed, no_further_action
    assigned_to UUID REFERENCES users(id),
    outcome TEXT,
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- TRAINING RECORDS
-- =============================================================
CREATE TABLE training_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES staff(id),
    training_name VARCHAR(255) NOT NULL,
    training_type VARCHAR(100) NOT NULL, -- mandatory, role_specific, leadership, refresher
    provider VARCHAR(255),
    delivery_method VARCHAR(50), -- in_person, e_learning, blended, on_the_job
    completion_date DATE,
    expiry_date DATE,
    certificate_number VARCHAR(100),
    pass_fail VARCHAR(10), -- pass, fail, pending
    score NUMERIC(5,2),
    status VARCHAR(50) NOT NULL DEFAULT 'booked', -- booked, in_progress, completed, expired, cancelled
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- DOCUMENTS
-- =============================================================
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL, -- service_user, staff, incident, referral, compliance
    entity_id UUID NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100) NOT NULL, -- care_plan, risk_assessment, consent_form, contract, certificate, report, correspondence
    file_path TEXT,
    file_size_bytes INTEGER,
    mime_type VARCHAR(100),
    version INTEGER NOT NULL DEFAULT 1,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    review_date DATE,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- COMPLIANCE CHECKS
-- =============================================================
CREATE TABLE compliance_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    check_name VARCHAR(255) NOT NULL,
    check_type VARCHAR(100) NOT NULL, -- cqc, health_safety, fire_safety, infection_control, medication, staffing, financial
    entity_type VARCHAR(50), -- service_user, staff, location, organisation
    entity_id UUID,
    due_date DATE NOT NULL,
    completed_date DATE,
    completed_by UUID REFERENCES users(id),
    result VARCHAR(50), -- pass, fail, partial, not_applicable
    score NUMERIC(5,2),
    notes TEXT,
    action_required TEXT,
    action_due_date DATE,
    action_completed_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, overdue, waived
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- INVOICES
-- =============================================================
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    service_user_id UUID NOT NULL REFERENCES service_users(id),
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    funder VARCHAR(255) NOT NULL, -- local authority, NHS, self-funder name
    funding_source VARCHAR(100) NOT NULL,
    line_items JSONB NOT NULL DEFAULT '[]',
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0,
    vat_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0,
    balance_due NUMERIC(10,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
    status VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft, sent, partial, paid, overdue, disputed, cancelled
    payment_date DATE,
    payment_reference VARCHAR(100),
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- PAYROLL INPUTS
-- =============================================================
CREATE TABLE payroll_inputs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES staff(id),
    pay_period_start DATE NOT NULL,
    pay_period_end DATE NOT NULL,
    regular_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    overtime_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    sleep_in_shifts INTEGER NOT NULL DEFAULT 0,
    holiday_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    sick_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    mileage NUMERIC(8,2) NOT NULL DEFAULT 0,
    expenses NUMERIC(8,2) NOT NULL DEFAULT 0,
    deductions NUMERIC(8,2) NOT NULL DEFAULT 0,
    deduction_notes TEXT,
    gross_pay NUMERIC(10,2),
    status VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft, submitted, approved, processed, paid
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(staff_id, pay_period_start, pay_period_end)
);

-- =============================================================
-- TASKS
-- =============================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    task_type VARCHAR(100), -- action, reminder, review, follow_up, assessment
    entity_type VARCHAR(50), -- service_user, staff, referral, incident, compliance
    entity_id UUID,
    assigned_to UUID REFERENCES users(id),
    created_by UUID REFERENCES users(id),
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    priority VARCHAR(20) NOT NULL DEFAULT 'medium', -- low, medium, high, urgent
    status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, in_progress, completed, cancelled, deferred
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- NOTIFICATIONS
-- =============================================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(100) NOT NULL, -- system, shift, medication, incident, compliance, task, document
    entity_type VARCHAR(50),
    entity_id UUID,
    channel VARCHAR(50) NOT NULL DEFAULT 'in_app', -- in_app, email, telegram, sms
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, sent, delivered, failed
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- AUDIT LOGS
-- =============================================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- create, update, delete, view, login, logout, export
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- INDEXES for performance
-- =============================================================
CREATE INDEX idx_referrals_status ON referrals(status);
CREATE INDEX idx_referrals_created_at ON referrals(created_at);
CREATE INDEX idx_service_users_status ON service_users(status);
CREATE INDEX idx_staff_status ON staff(status);
CREATE INDEX idx_shifts_date ON shifts(shift_date);
CREATE INDEX idx_shifts_status ON shifts(status);
CREATE INDEX idx_shift_assignments_shift_id ON shift_assignments(shift_id);
CREATE INDEX idx_shift_assignments_staff_id ON shift_assignments(staff_id);
CREATE INDEX idx_medication_logs_service_user ON medication_logs(service_user_id);
CREATE INDEX idx_medication_logs_scheduled_time ON medication_logs(scheduled_time);
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_severity ON incidents(severity);
CREATE INDEX idx_safeguarding_status ON safeguarding_reports(status);
CREATE INDEX idx_compliance_due_date ON compliance_checks(due_date);
CREATE INDEX idx_compliance_status ON compliance_checks(status);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- =============================================================
-- UPDATED_AT trigger function
-- =============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all mutable tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON referrals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_users_updated_at BEFORE UPDATE ON service_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shifts_updated_at BEFORE UPDATE ON shifts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shift_assignments_updated_at BEFORE UPDATE ON shift_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medication_logs_updated_at BEFORE UPDATE ON medication_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_safeguarding_updated_at BEFORE UPDATE ON safeguarding_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_training_updated_at BEFORE UPDATE ON training_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_compliance_updated_at BEFORE UPDATE ON compliance_checks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payroll_updated_at BEFORE UPDATE ON payroll_inputs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
