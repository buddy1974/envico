# Envico CareOS 2026

Automation platform for supported living and domiciliary care providers.

## Built With

- n8n automation engine
- PostgreSQL / Supabase
- AI assistant layer
- Vercel dashboard

## Purpose

Manage care operations, compliance, staffing, finance, and executive reporting.

## Project Structure

```
envico
├── docs/           — Project documentation
├── workflows/      — n8n automation workflows
├── database/       — Database schemas and migrations
├── dashboard/      — Web admin panel (Vercel)
├── scripts/        — Utility scripts
└── env/            — Environment configuration templates
```

## Modules

| Module | Description | Status |
|--------|-------------|--------|
| 01 — Referral Intake Engine | n8n referral processing workflows | In Progress |
| 02 — Service User Management | Profiles, care plans, risk assessments | Planned |
| 03 — Staff & Scheduling | Shifts, rotas, assignments | Planned |
| 04 — Medication Management | MAR sheets, logs, alerts | Planned |
| 05 — Compliance & Safeguarding | CQC compliance, incident tracking | Planned |
| 06 — Finance & Payroll | Invoicing, payroll, reporting | Planned |

## Getting Started

1. Clone this repository
2. Copy `env/.env.example` to `.env` and fill in credentials
3. Configure your n8n instance with the workflows in `workflows/`
4. Set up your PostgreSQL/Supabase database using `database/schema.sql`
5. Deploy the dashboard to Vercel
