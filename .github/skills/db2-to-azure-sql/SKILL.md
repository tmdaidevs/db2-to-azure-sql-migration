---
name: db2-to-azure-sql
description: Autonomously analyze an SSMA for Db2 project, remediate unsupported objects, migrate DB2 schemas and data to Azure SQL, and validate the result. Use when a user provides a DB2 migration folder or asks to migrate DB2 to Azure SQL.
---

# DB2 to Azure SQL Migration

Act as a migration operator, not an AI-only code generator. Use SQL Server Migration Assistant (SSMA) as the deterministic migration engine. Use AI only to remediate objects that SSMA cannot safely convert. Treat `input/` as the customer drop zone: discover complete SSMA projects below it and write generated results only to `migration-artifacts/`.

Use `scripts/orchestrate.ps1` as the stateful controller. It is the normal entry point for a run; it invokes validation, discovery, manifest, dependency, compatibility, and evidence stages and persists phase state after each stage.

## Operating boundary

- Work only inside the user-provided migration folder and explicitly approved temporary locations.
- Never invent missing source definitions, tables, columns, types, data, or business rules.
- Never expose, commit, or print secrets.
- Keep generated SQL, logs, reports, and manifests in a git-ignored migration-artifacts directory.
- Treat generated T-SQL as a candidate until it compiles and passes validation.
- Do not perform production cutover, destructive actions, or source writes without explicit confirmation.

## Interactive intake

At the start of a connected migration, ask one question at a time in chat and persist the answers locally in `.env`. Do not wait for a pre-existing `.env`; create it from the chat answers. Create `.env.example` with names only and ensure `.env` is git-ignored.

Collect:

- DB2 platform and version: LUW, z/OS, or iSeries
- DB2 host, port, database, schema scope, code page, locale, timezone, and read-only status
- Azure SQL target: Database or Managed Instance, server, database, region, compatibility level
- Authentication method and migration identity
- Migration mode: offline analysis, isolated staging, rehearsal, or production
- Data movement strategy, downtime window, synchronization requirement, batch size, timeout, retries, and parallelism
- Whether SSMA compatibility helpers such as `ssma_db2` are permitted
- Array and user-defined type mapping decisions, or permission to propose them
- Golden test cases, reconciliation queries, critical objects, performance thresholds, and rollback requirements
- Explicit authorization for destructive target actions and production cutover

Validate required values and connectivity before migration. If a required value is missing, ask for it in chat at the point it is needed. Use managed identity or an approved secret store where available; do not place credentials in command arguments, reports, or generated SQL.

## Artifact discovery and manifest

Recursively inspect the folder and identify SSMA projects, preferences, metadata, assessment reports, conversion reports, source SQL, target SQL, HTML detail pages, XML/Excel reports, and report timestamps.

Build a manifest with one record per object:

- schema, name, type, source definition, target definition, and provenance
- report run and SSMA version
- errors, warnings, estimated effort, and object identifiers
- referenced tables, columns, functions, sequences, and user-defined types
- deployment, compilation, test, approval, and final status

Keep schemas and report runs separate. Prefer complete source definitions over header-only captures. Preserve the selected artifact and its provenance.

Classify objects as `ready`, `warning`, `requires-remediation`, `blocked`, or `not-assessed`. Cluster remediation by repeated error codes and syntax patterns, but retain object-level evidence.

## Object-by-object processing

Do not stop after analyzing the first error category or only process functions. For every in-scope object, resolve the strongest source and target artifacts, extract its contract, identify dependencies, assess its SSMA status, and run the applicable conversion and validation gates.

Use these object-specific rules:

- **Schemas:** verify names, ownership, authorization, collation, and target platform compatibility.
- **User-defined types:** verify scalar, distinct, structured, XML, and array semantics; map each type explicitly before dependent objects are compiled.
- **Tables:** compare columns, nullability, defaults, generated values, identity behavior, computed expressions, LOB/XML/spatial data, keys, and row-count expectations.
- **Sequences:** compare start, increment, minimum, maximum, cycle behavior, cache behavior, and current value after data load.
- **Indexes:** compare key order, included columns, uniqueness, filtered predicates, clustering, and whether the target optimizer needs a revised design.
- **Constraints:** validate primary keys, foreign keys, unique constraints, checks, and enforcement timing. Deploy in dependency order and test referential integrity.
- **Views:** compare output columns, data types, null behavior, joins, filters, grouping, ordering assumptions, and dependent objects.
- **Functions:** extract the signature and return contract, convert in dependency order, and compare exact outputs across generated boundary cases.
- **Procedures:** extract input/output parameters, result sets, side effects, handlers, transaction boundaries, dynamic SQL, and error/status contracts. Compare data effects and outputs, not only compilation.
- **Triggers:** inspect firing timing, affected rows, recursion, transition values, transaction behavior, and ordering assumptions. Test insert, update, delete, and multi-row statements.
- **Synonyms, aliases, packages, and other objects:** resolve each referenced object and either convert it, replace it with an approved target construct, or mark it explicitly blocked.

For each object, execute the same lifecycle:

```text
DISCOVERED
→ SOURCE_RESOLVED
→ CONTRACT_EXTRACTED
→ DEPENDENCIES_RESOLVED
→ SSMA_RESULT_CLASSIFIED
→ BASELINE_OR_CANDIDATE_SELECTED
→ COMPILED
→ BEHAVIOR_VALIDATED
→ APPROVED
→ DEPLOYED
```

An object is not complete because a target script exists. A target script is only deployable after its applicable compile, dependency, semantic, data-effect, and performance checks pass.

After each object, update the manifest and dependency graph immediately. Recompute the next ready objects from the graph, so a failed object blocks only its dependents and does not hide unrelated migration progress.

## Target decision

Do not assume that an SSMA project targeting SQL Server 2019 is already suitable for Azure SQL.

Use Azure SQL Managed Instance as the compatibility-first target when the workload needs legacy or instance-level behavior, cross-database access, SQL Agent, linked systems, or minimal application change. Use Azure SQL Database only after confirming that the application and converted objects fit its feature and transaction boundaries.

Record the target platform, compatibility level, collation, timezone, authentication, network path, and compatibility-helper policy in the manifest.

## Execution phases

### 1. Preflight

Confirm that the folder, SSMA outputs, complete source definitions, source connection, destination connection, target database, permissions, and test inputs are sufficient. In offline mode, stop at analysis and candidate generation; never claim data or behavioral migration.

### 2. Baseline

Deploy SSMA-prepared objects without unnecessary AI rewriting, in dependency order:

1. schemas
2. supported types
3. tables and columns
4. sequences
5. keys and constraints
6. indexes
7. views
8. procedures
9. functions
10. triggers and remaining programmable objects

Use an isolated target database first. Make deployment idempotent, checkpointed, resumable, and object-level observable.

### 3. Remediation

Process all failed and warning objects in dependency order, not only functions:

1. type and schema blockers
2. tables, sequences, constraints, and indexes
3. views and other query objects
4. deterministic scalar functions
5. scalar functions that read tables
6. procedures and functions with side effects or handlers
7. triggers and application-contract objects
8. objects blocked by unsupported types or missing source

For each candidate, provide the complete DB2 source, SSMA diagnostics and output, signature, exact dependencies, target platform, approved mappings, known semantic differences, and required tests. Return T-SQL, assumptions, risks, unresolved items, and tests. Do not accept output that relies on undocumented assumptions.

For arrays and user-defined types, first determine whether they are inputs, outputs, local state, persisted data, iteration structures, or application contracts. Then choose and record JSON, normalized tables, table-valued parameters, staging tables, or another approved design. Stop for a human decision if the mapping changes an application contract or cannot be inferred safely.

### 4. Validation gates

Every baseline or remediated object must pass:

1. syntax and static compatibility checks
2. dependency existence checks
3. isolated target compilation
4. object-specific semantic tests
5. source-versus-target behavior tests where the source is reachable
6. data-effect and transaction tests for procedures and triggers
7. performance checks for database-reading objects
8. approval rules defined by the intake

Generate boundary tests for nulls, empty values, invalid dates, leap years, month ends, Unicode, rounding, missing rows, duplicate rows, and error outputs. Compare procedure output parameters, row effects, status codes, and transaction behavior.

For objects that cannot be behaviorally compared because the source is unavailable, mark them `static-only` and do not report full migration success. Require explicit acceptance of that limitation.

### 5. Data migration

Only after schema and object gates pass, migrate data with the approved SSMA or Azure migration mechanism. Capture row counts, deterministic aggregates or checksums, rejected rows, nullability/type exceptions, referential integrity, and sequence alignment. Make failed batches resumable. Re-run dependent object tests after data migration because data-dependent behavior may differ from empty-database compilation.

### 6. Reconciliation and cutover

Run application smoke tests, business reconciliation queries, performance tests, and a cutover rehearsal. Keep rollback evidence. Production cutover is a separate explicit confirmation gate.

## Autonomous execution controls

When connected execution is authorized, orchestrate SSMA through its supported project and script-file commands rather than guessing command-line switches. Use the existing project when its target and settings are correct; otherwise create a derived project with the explicit Azure target and preserve the original unchanged.

Run SSMA stages with detailed reports and fail-fast behavior:

1. connect and force-load source metadata
2. connect and force-load target metadata
3. refresh source metadata when the source is reachable
4. generate assessment reports with verbose errors
5. convert schema
6. review and classify conversion output
7. synchronize only approved baseline objects
8. migrate data
9. generate and archive synchronization and data-migration reports

Treat SSMA reports as execution evidence, not just display output. Each command must have a unique run directory, captured inputs, exit status, output report, error report, and checkpoint. Never continue after a connection, metadata, schema synchronization, or data-migration failure unless the failure is classified as non-blocking and the dependency graph confirms that continuation is safe.

Use a state machine that can resume after interruption:

```text
PREFLIGHT → ASSESSED → CONVERTED → BASELINE_DEPLOYED
→ REMEDIATED → CODE_VALIDATED → DATA_MIGRATED
→ RECONCILED → CUTOVER_READY → CUTOVER_CONFIRMED
```

Persist state after every object and phase. Retrying must be bounded, use exponential backoff for transient connectivity failures, and never repeat a non-idempotent operation without checking its prior result.

## Environment and security

Use `.env` only for local non-committed configuration and secret references. Prefer Microsoft Entra authentication, managed identity for Azure-hosted execution, and a secret manager for DB2 credentials. Validate that `.env` is ignored before writing it. Redact passwords, tokens, connection strings, row values, and sensitive SQL literals from console output, logs, manifests, and chat.

Validate:

- TLS and certificate requirements
- source and target network reachability
- least-privilege permissions
- target database isolation
- approved region and service tier
- storage capacity and transaction-log headroom
- backup, restore, and rollback readiness

Do not create or modify Azure resources implicitly. If infrastructure is missing, report the exact prerequisite and stop unless provisioning was explicitly authorized.

## Data and operational safety

Before loading data, record source counts or deterministic aggregates for every in-scope table and identify tables that cannot be safely compared. Preserve source encoding, collation, timezone, decimal precision, timestamp precision, LOB handling, and identity/sequence semantics.

For large or production workloads, determine whether an officially supported online or change-synchronization path exists for the selected source and target. Do not assume that a generic SSMA rerun provides continuous replication. If only offline migration is available, enforce the approved write-free window and verify source quiescence before the final load.

Protect against:

- accidental target truncation or drop
- duplicate loads
- disabled constraints left unenforced
- sequence values behind imported data
- partial LOB or Unicode migration
- timezone and daylight-saving differences
- trigger recursion or changed firing behavior
- transaction and commit differences
- unbounded loops and runaway cleanup jobs

## Autonomous stopping rules

Stop and report a blocker when:

- required source or target connectivity is unavailable
- the target platform is undecided or incompatible
- a complete source definition is missing
- a dependency cannot be resolved
- an array or user-defined type changes an application contract without an approved mapping
- a candidate does not compile after bounded remediation attempts
- source and target behavior differs without an explicit accepted rule
- data reconciliation fails
- security, permission, capacity, or rollback prerequisites are not met

The skill may continue with independent objects, but it must not label the migration complete while blocked objects or unvalidated data remain.

## Capability-gap and self-optimization workflow

When a request is not directly supported, do not simply stop. Start a capability-gap workflow:

1. Describe the requested outcome and the exact unsupported capability.
2. Search the current skill, scripts, policy, input artifacts, and available runtime tools for an existing path.
3. Classify the gap as configuration, missing adapter, missing parser, missing conversion pattern, missing validator, unsupported target feature, or unsafe/forbidden operation.
4. Determine whether the gap can be fulfilled without inventing source semantics, weakening safety gates, exposing secrets, or changing production state.
5. Create a scoped extension proposal in `migration-artifacts/capability-gaps/<id>/` containing the gap, evidence, proposed workflow, files to change, risks, tests, and rollback.
6. Implement the smallest reusable extension when it is safe and within the package scope. Otherwise ask for the specific missing decision or prerequisite in chat.
7. Run policy validation, script syntax checks, fixture tests, and the narrowest relevant workflow test.
8. Record the improvement in the manifest and final report, including whether it was applied, deferred, or rejected.

Self-optimization is bounded: the skill may add reusable adapters, parsers, patterns, validators, and documentation, but must not silently remove validation, broaden permissions, disable confirmations, change target policy, or modify its own governing instructions without an auditable proposal and explicit approval. Never use generated code to grant itself credentials or access.

## Project prioritization

When multiple schemas or projects are supplied:

- Keep each SSMA project and schema as a separate migration unit.
- Start with a small, low-risk unit as the pilot.
- Deploy SSMA-ready objects before remediating failed objects.
- Start remediation with deterministic scalar functions, then table-reading functions, procedures, handlers, and triggers.
- Investigate unhandled exceptions separately from language conversion.
- Resolve unsupported types from actual usage, not names alone.
- Defer large routines until dependencies and helper objects are stable.

## Completion contract

Report success only when every in-scope object has a final status, no blocking failures remain, target objects compile, data reconciliation passes, required behavior and performance tests pass, and cutover requirements are satisfied.

For a sanitized or offline run, report completion only for the simulated scope and label it `simulated`; never present it as proof of live DB2/Azure SQL compatibility or data migration.

Always produce:

- sanitized migration manifest
- object status and dependency report
- SSMA baseline results
- remediation candidates, accepted versions, and rejected versions
- source/target validation evidence
- data migration results
- unresolved risks and explicit blockers
- rollback and cutover notes

The governing rule is: **autonomous execution, never autonomous invention**.
