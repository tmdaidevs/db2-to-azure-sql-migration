# DB2 to Azure SQL migration skill

This folder is the input package for the `db2-to-azure-sql` GitHub skill. The skill analyzes SSMA output, deploys the deterministic baseline, remediates unsupported objects, migrates data, and validates the result.

## First-version layout

- `.github/skills/db2-to-azure-sql/SKILL.md` - orchestration rules and safety contract
- `.env.example` - configuration template; copy to `.env` locally
- `.gitignore` - prevents secrets and generated artifacts from being committed
- `config/migration-policy.json` - safe execution defaults and required evidence
- `validation/` - customer-approved validation query/test inputs
- `scripts/preflight.ps1` - validates the folder and required environment
- `scripts/analyze-ssma.ps1` - inventories SSMA report files
- `scripts/build-manifest.ps1` - creates an object manifest from available source artifacts
- `scripts/build-dependencies.ps1` - creates a conservative dependency graph
- `scripts/validate-policy.ps1` - validates migration safety policy
- `scripts/detect-runtime.ps1` - detects SSMA, provider, and SQL client prerequisites
- `scripts/check-compatibility.ps1` - screens source artifacts for target-platform risks
- `scripts/create-ssma-script.ps1` - generates a reviewable SSMA script plan
- `scripts/new-run.ps1` - creates a run-specific artifact directory
- `scripts/write-state.ps1` - persists resumable migration state
- `scripts/rollback-plan.ps1` - creates a non-destructive rollback plan
- `scripts/invoke-ssma.ps1` - captures an explicitly supplied SSMA Console invocation
- `scripts/invoke-sql.ps1` - guarded SQL execution hook
- `scripts/invoke-db2.ps1` - read-only DB2 validation adapter using the configured provider
- `scripts/generate-report.ps1` - creates a consolidated migration evidence report
- `scripts/compare-results.ps1` - compares normalized source and target results
- `scripts/run-sanitized-pilot.ps1` - runs the complete workflow against synthetic fixtures
- `tests/fixtures/` - synthetic source/target validation fixtures
- `config/ServersConnectionFile.example.xml` - sanitized SSMA server-file template
- `scripts/run-migration.ps1` - safe offline/plan entry point
- `input/` - customer drop zone for SSMA projects and reports

## Where to place SSMA output

Place the complete SSMA project folder below `input/`. The existing project is organized as:

```text
DB2TOASQL/
└── input/
    └── CustomerProject/
        ├── *.db2ssproj
        ├── *.prefs
        ├── *.mb
        ├── *.mappings
        └── report/
            └── report_<timestamp>/
```

The customer uploads or copies new SSMA assessment, conversion, synchronization, and data-migration output into `input/`. Keep each complete SSMA project in its own subfolder. Do not manually edit SSMA reports. Keep every report run so the skill can compare runs and select the strongest available source and target artifacts.

If there are multiple SSMA projects, place each project in its own `input/` subfolder, for example `input/ProjectA/` or `input/ProjectB/`. Do not merge report folders from different projects or schemas.

The skill scans recursively below `input/`. SSMA output must not be placed inside `migration-artifacts/`, because that directory is reserved for generated manifests, logs, checkpoints, candidates, and validation evidence.

## Current behavior

The first version safely supports offline discovery and planning. It does not claim to perform a connected migration yet. Connected execution must be added only after the SSMA Console installation, script-file format, Azure target, authentication, and validation database strategy are confirmed.

The SSMA wrapper intentionally requires the caller to provide the installed executable, script file, and arguments. This avoids embedding unverified SSMA command-line assumptions in the package.

To generate a reviewable SSMA script plan after the customer provides the source and target server names:

```powershell
.\scripts\create-ssma-script.ps1 -SourceServerName DB2_SOURCE -TargetServerName AZURE_SQL_TARGET
```

The generated XML is written to `migration-artifacts/`. It must be reviewed before execution; the first version never runs a generated migration script implicitly.

To analyze the supplied project without connecting:

```powershell
.\scripts\run-migration.ps1 -Offline
```

To exercise the complete workflow without customer systems or data:

```powershell
.\scripts\run-migration.ps1 -SanitizedPilot
```

The sanitized pilot is the executable regression path for the package. It proves orchestration and evidence handling, but it does not prove connectivity or behavior against a real DB2 or Azure SQL system.

To create a local configuration interactively:

```powershell
.\scripts\initialize-env.ps1
```

The interactive script is a local convenience. In the GitHub skill workflow, the equivalent questions are asked in chat and the answers are persisted locally.

Never commit `.env`, database exports, customer data, passwords, tokens, or generated migration artifacts.
