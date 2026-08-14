# Personal AI Usage Charter (DWP Endpoint Engineer)

## Purpose
I use public AI assistants to speed up endpoint support and improve quality, while protecting users, systems, and DWP information. AI helps me draft and think; it does not replace policy, security controls, or engineering judgment.

## Scope
Applies to my desktop/endpoint work (Windows 10/11 support, Microsoft 365 client issues, device troubleshooting, script drafting, change notes, and runbook updates).

## 1) Public LLM Tasks I Will Use
I will use public AI for low-risk, sanitized, non-sensitive work:

- Drafting generic PowerShell or CMD snippets (no real tenant, user, or device data).
- Building troubleshooting checklists for endpoint issues (slow login, Teams audio issues, Outlook launch/perf, print mapping, OneDrive sync, VPN client checks).
- Rewriting ticket summaries, known-error notes, handover notes, and end-user communications for clarity.
- Creating test plans for scripts (success criteria, failure checks, rollback checks).
- Explaining common Windows event log patterns or error categories in abstract terms.

Operational rule: prompts must be minimal, generic, and sanitized before sending.

## 2) Public LLM Tasks I Will Not Use
I will not use public AI for:

- Any work requiring internal-only DWP architecture, network details, security controls, or unpublished operational information.
- Pasting full incidents, logs, screenshots, exports, or chat transcripts containing identifiable users, device names tied to users, internal addresses, or business-sensitive metadata.
- Requests that produce final production decisions on access changes, security exceptions, firewall/proxy changes, or privileged operations.
- Executing AI-generated remediation in production without independent validation and change discipline.

Decision rule: if I need real environment data to solve it, I stop and use approved internal tooling/processes.

## 3) Data-Handling Rule (PII and Credentials)
Non-negotiable personal rule:

- Never share credentials, passwords, tokens, API keys, MFA codes, recovery codes, cookies, or secrets.
- Never share end-user PII (name, email, phone, employee ID, address, or combinations that identify a person).
- Sanitize all prompts: replace user/device/org identifiers with placeholders such as USER_A, DEVICE_01, SITE_X, DOMAIN_Y.
- Remove internal URLs, hostnames, IPs, ticket IDs, and exact timestamps unless essential, and then generalize.
- Share only the least data needed for the immediate question.

If sanitization is not possible, do not use a public AI assistant.

## 4) Personal Generate-Then-Verify Rule (Scripts and Changes)
I treat AI output as draft content only.

Generate:

- Ask for the smallest safe script/change that solves one problem.
- Require assumptions, prerequisites, and rollback steps in the output.

Verify before any execution:

- Read every command line-by-line.
- Validate switches, paths, and blast radius.
- Check for unsafe behavior (broad deletes, silent privilege escalation, hidden downloads, uncontrolled loops).
- Cross-check against official vendor documentation and DWP standards.
- Test on non-production endpoint(s) first with clear pass/fail criteria.

Deploy:

- Follow normal change control for production-impacting actions.
- Run with least privilege.
- Record what AI generated, what I changed, test evidence, and final outcome.

## Commitment
I remain accountable for all outputs, commands, and changes. Public AI is a drafting assistant, not a decision authority.

Date: 2026-08-14
Owner: DWP Endpoint Engineer (Personal Charter)
