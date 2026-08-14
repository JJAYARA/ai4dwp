# Security Escalation Note - Floor 6 Copilot Access Concern

## What this actually is
This is a potential unauthorized information exposure incident, not just a login or performance symptom. The report indicates a possible access-control or data-index-permissions issue in the Copilot retrieval path and requires security/governance triage in parallel with endpoint incident work.

## What we should not do
- Do not close or downgrade this as "AI weirdness" without evidence.
- Do not rely on recollection alone; preserve prompt/output evidence and validate ACLs before drawing conclusions.
- Do not delay security engagement until endpoint troubleshooting is complete.

## Two-sentence escalation draft
Security escalation: A Floor 6 user reports Copilot surfaced a client matter they are not authorized to access, which must be treated as a potential unauthorized information exposure and possible permissions or indexing-control failure. Please assign immediate Security and Data Governance triage to preserve prompt/output evidence, validate effective source ACLs and group memberships, assess blast radius, and implement temporary containment while root cause is confirmed.
