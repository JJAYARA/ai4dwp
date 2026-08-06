# Personal AI Usage Charter (DWP Desktop and Endpoint Engineering)

## Purpose
I use public AI assistants to improve speed and quality of endpoint support work while protecting users, systems, and DWP information. This charter defines what I will and will not use public AI for, and the controls I apply every time.

## Scope
Applies to my day-to-day desktop and endpoint activities, including Windows client support, software packaging basics, troubleshooting steps, scripting drafts, and documentation.

## 1) Appropriate DWP Tasks for Public LLM Help
I may use public AI assistants for low-risk, non-sensitive work such as:

- Drafting or improving generic PowerShell, batch, or command-line snippets that do not include live environment data.
- Explaining Windows concepts, logs, error patterns, and likely root-cause paths in abstract terms.
- Creating troubleshooting checklists for common endpoint issues such as Outlook startup delays, profile corruption, patching checks, printer mapping, and device performance triage.
- Rewriting ticket notes, handover text, known-error articles, and user communications into clearer language.
- Generating template runbooks for activities like software install validation, reboot sequencing, rollback planning, and post-change checks.
- Producing test ideas and validation criteria for scripts before use in production.

Rule: prompt with sanitized, minimal context only, and keep it generic unless approved data-sharing controls exist.

## 2) Tasks Not Appropriate for Public LLMs
I will not use public AI assistants for:

- Any task that requires sharing internal-only DWP information, protected architecture details, unpublished policies, or operational security controls.
- Copying and pasting incident tickets, chat transcripts, screenshots, or logs that contain user identifiers, hostnames tied to users, internal addresses, or service desk metadata not already public.
- Uploading scripts, configs, registry exports, or endpoint inventories from production if they include identifiable users, credentials, tokens, or internal environment specifics.
- Asking AI to make final production decisions on remediation, privilege changes, firewall or proxy rules, or security control exceptions.
- Using AI outputs directly for live changes without independent verification and change discipline.

Rule: if in doubt, do not paste it.

## 3) Data-Handling Rule for End-User PII and Credentials
Non-negotiable handling standard:

- Never share credentials, secrets, API keys, access tokens, MFA details, recovery codes, or session cookies with public AI.
- Never share end-user PII, including names, emails, phone numbers, employee identifiers, home addresses, or any combination that can identify a person.
- Sanitize all prompts before use by removing or replacing user and device identifiers, internal URLs, IPs, tenant details, ticket references, and exact timestamps or location data when not needed.
- Use placeholders such as USER_A, DEVICE_01, DOMAIN_X, and MAILBOX_Y.
- Keep prompt data to the least necessary detail and only for the immediate technical question.
- If the task needs real data to solve, stop and use approved internal tooling or escalation paths instead of public AI.

## 4) Personal Generate-Then-Verify Rule (Scripts and System Changes)
I treat AI output as a draft, never as authority.

Generate:
- Ask AI for a script or change plan in the smallest possible scope.
- Request explicit assumptions, prerequisites, and rollback steps.

Verify:
- Read every line before execution.
- Check command intent, parameters, paths, and side effects.
- Confirm script safety: no hidden downloads, privilege abuse, broad deletes, or uncontrolled loops.
- Validate against official vendor documentation and DWP standards.
- Test first in a safe environment or non-production endpoint.
- Capture expected results, failure conditions, and rollback evidence.

Deploy:
- Apply normal change control for production-impacting actions.
- Run with least privilege needed.
- Record what was generated, what was edited, what was tested, and the outcome.

Post-check:
- Confirm system health, user impact, and service restoration.
- Update documentation with verified steps only.

## Personal Commitment
I use public AI to accelerate thinking, drafting, and analysis, not to bypass security, governance, or engineering judgment. I remain accountable for every command I run and every change I implement.
