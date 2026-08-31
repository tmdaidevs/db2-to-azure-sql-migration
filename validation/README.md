# Validation inputs

Place customer-approved, sanitized validation assets here. Do not commit production extracts or secrets.

Recommended assets:

- source and target row-count queries
- deterministic aggregate or checksum queries
- function input/output cases
- procedure input/output and side-effect cases
- trigger insert/update/delete cases
- performance thresholds
- business reconciliation queries

Every query or test case should state its expected result or comparison rule and identify the source and target objects it covers.

The sample result files are synthetic fixtures for the result-comparison harness and contain no customer data. Replace them only with approved, sanitized test outputs.

Use `contract.example.json` as the shape for object-level source/target validation contracts. Contracts must be approved before connected execution.
