# Envico CareOS 2026 — Project Header

**Platform:** Supported Living & Domiciliary Care Automation
**Version:** 2026.1
**Status:** Active Development

---

## Mission

To provide a fully automated, AI-assisted care operations platform that enables care providers to manage compliance, staffing, finance, and service delivery from a single integrated system.

---

## Architecture

```
n8n Automation Engine
    ↓
PostgreSQL / Supabase (Data Layer)
    ↓
AI Assistant Layer (Claude / OpenAI)
    ↓
Vercel Dashboard (Web Interface)
```

---

## Core Domains

1. **Referral & Intake** — Automated referral processing and placement decisions
2. **Service User Management** — Care plans, risk assessments, profile management
3. **Staff & Workforce** — Scheduling, rotas, training, HR compliance
4. **Medication Management** — MAR, administration logs, alerts
5. **Compliance & Safeguarding** — CQC readiness, incident reporting, investigations
6. **Finance & Reporting** — Invoicing, payroll, executive dashboards

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Automation | n8n |
| Database | PostgreSQL via Supabase |
| AI Layer | Claude (Anthropic) + OpenAI |
| Dashboard | Next.js on Vercel |
| Notifications | Email SMTP + Telegram |
| Auth | Supabase Auth |

---

*Envico CareOS 2026 — Built for regulated care environments.*
