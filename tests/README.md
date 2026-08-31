# Sanitized test fixtures

Fixtures are synthetic and contain no customer data. Each fixture must include `source.sql`, `target.sql`, and `cases.json`. They cover scalar functions, procedures with transaction semantics, and unsupported array-type decisions. They validate package parsing and candidate-contract handling; live DB2/Azure SQL behavior still requires connected execution.
