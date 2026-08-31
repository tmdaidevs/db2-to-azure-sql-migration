# First-run onboarding

The `db2-to-azure-sql` skill is intentionally guided. On the first run, it asks one question at a time in chat, validates each phase, and resumes from the last completed phase.

## Before starting

1. Copy the complete SSMA project and reports below `input/`.
2. Do not edit SSMA reports.
3. Do not put passwords, tokens, or production data in the repository.
4. Have access to the DB2 provider selected in SSMA and an isolated Azure SQL staging target.

## Guided phases

1. Package and migration scope
2. DB2 source and SSMA provider
3. Azure SQL target
4. Migration policy and downtime
5. Validation tests and reconciliation
6. Staged execution
7. Optional production cutover

The skill stores non-secret configuration locally in `.env` and keeps generated state and evidence in `migration-artifacts/`. Production cutover always requires a separate explicit confirmation.

To inspect the next configuration phase without revealing values:

```powershell
.\scripts\onboarding-status.ps1
```

