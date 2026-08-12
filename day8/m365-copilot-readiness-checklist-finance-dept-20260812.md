# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** [Financial Services Company]
**Department:** Finance (~200 users)
**Prepared by:** DWP Engineer
**Date:** 2026-08-12
**Status:** Pre-deployment

---

> **Risk Notice:** This department holds payroll, board packs, M&A documents, and client financial data. SharePoint permissions were inherited from a 2019 migration and have never been audited. **Permissions and oversharing remediation must be completed and signed off before Copilot licences are assigned.** Copilot surfaces data the user can access — if permissions are too broad, Copilot will surface data that should not be visible.

---

## How to use this checklist

Work through each section in order. Sections are sequenced by dependency and risk. Do not proceed to licence assignment (Section 6) until Sections 3 and 4 are fully signed off. Use the **Owner** column to assign accountability. Mark each item `[x]` when confirmed complete with evidence.

---

## Section 1 — Licensing Prerequisites

| # | Check | Owner | Done |
|---|-------|-------|------|
| 1.1 | Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence in Entra ID | Licence Admin | `[ ]` |
| 1.2 | Confirm no users are on E3 or legacy SKUs that do not include the required service plans (Exchange Online P2, SharePoint Online P2, Teams) | Licence Admin | `[ ]` |
| 1.3 | Confirm **Microsoft 365 Copilot add-on** licences have been procured for the Finance cohort (quantity matches headcount including any shared/service accounts to be excluded) | Licence Admin | `[ ]` |
| 1.4 | Identify and exclude shared mailboxes, service accounts, and room resources from the Copilot licence assignment scope | Licence Admin | `[ ]` |
| 1.5 | Confirm billing/procurement approval is in place before any licence assignment occurs | Finance Owner | `[ ]` |

---

## Section 2 — Microsoft 365 Apps Client Version Requirements

| # | Check | Owner | Done |
|---|-------|-------|------|
| 2.1 | Confirm all Finance devices are running **Microsoft 365 Apps for Enterprise** (not Office 2019/2021 perpetual) | Endpoint/DWP | `[ ]` |
| 2.2 | Confirm Microsoft 365 Apps build is on **Current Channel** or **Monthly Enterprise Channel** at a supported Copilot build (minimum: Version 2302, Build 16130 or later — validate against current Microsoft guidance at time of deployment) | Endpoint/DWP | `[ ]` |
| 2.3 | Run an Intune/SCCM compliance report to identify any devices below the minimum build; remediate before pilot | Endpoint/DWP | `[ ]` |
| 2.4 | Confirm update channel policy is enforced via Intune or Group Policy — no user-managed update rings | Endpoint/DWP | `[ ]` |
| 2.5 | Confirm Microsoft Teams desktop client is up to date (Teams 2.x / new Teams preferred; Copilot in Teams requires new Teams) | Endpoint/DWP | `[ ]` |
| 2.6 | Confirm users are not running Microsoft 365 Apps exclusively via browser (Web Apps do not support all Copilot features) | Endpoint/DWP | `[ ]` |

---

## Section 3 — Identity and MFA Readiness

| # | Check | Owner | Done |
|---|-------|-------|------|
| 3.1 | Confirm all Finance users are authenticating via **Entra ID (Azure AD)** — no on-prem-only accounts | Identity/IAM | `[ ]` |
| 3.2 | Confirm **MFA is enforced** for all Finance users via Conditional Access policy (not just Security Defaults) | Identity/IAM | `[ ]` |
| 3.3 | Confirm no Finance users are excluded from MFA Conditional Access policies via named exclusions or legacy authentication exemptions | Identity/IAM | `[ ]` |
| 3.4 | Confirm **legacy authentication protocols** (Basic Auth, IMAP, POP, SMTP Auth) are blocked for all Finance accounts | Identity/IAM | `[ ]` |
| 3.5 | Confirm Entra ID sign-in risk and user risk policies are active for the Finance cohort | Identity/IAM | `[ ]` |
| 3.6 | Confirm all Finance users have completed MFA registration (check registration report in Entra ID > Authentication Methods > User Registration Details) | Identity/IAM | `[ ]` |
| 3.7 | Confirm no Finance accounts have persistent admin roles (Global Admin, SharePoint Admin, etc.) assigned directly — use PIM where elevated access is required | Identity/IAM | `[ ]` |

---

## ⚠️ Section 4 — SharePoint / OneDrive Permissions and Oversharing Audit
### HIGHEST PRIORITY — Must be completed and formally signed off before Copilot licence assignment

> **Why this is the critical gate:** Microsoft 365 Copilot respects existing Microsoft 365 permissions — it will retrieve and surface any document a user has access to. Because Finance department permissions were inherited from a 2019 migration and have never been audited, it is highly likely that overly broad access exists across sites containing payroll, board packs, M&A material, and client financial data. Copilot will find and present this data in response to natural language prompts. Remediating this after Copilot is live is significantly harder than doing it now.

#### 4a — SharePoint Site and Library Audit

| # | Check | Owner | Done |
|---|-------|-------|------|
| 4a.1 | **Enumerate all SharePoint sites** used by or accessible to Finance users — use SharePoint Admin Centre > Active Sites and filter by Finance-associated owners/members | SharePoint Admin | `[ ]` |
| 4a.2 | For each site identified, **export the full permissions report** (Site Permissions > Check Permissions) and document all users, groups, and sharing links with access | SharePoint Admin | `[ ]` |
| 4a.3 | Identify sites where **"Everyone"**, **"Everyone except external users"**, or **"All Company"** groups have been granted access — these are immediate remediation targets | SharePoint Admin | `[ ]` |
| 4a.4 | Identify sites that were migrated in 2019 and still carry **inherited permissions from the source system** — compare current permission groups against expected Finance team membership | SharePoint Admin | `[ ]` |
| 4a.5 | Review all **SharePoint Groups** on Finance sites: remove stale users (leavers, movers, contractors whose engagement has ended) | SharePoint Admin | `[ ]` |
| 4a.6 | Check for **broken inheritance** (library or folder-level permissions that differ from site-level) — document and remediate where unjustified | SharePoint Admin | `[ ]` |
| 4a.7 | Confirm no Finance sites containing sensitive data (payroll, M&A, board packs) are configured as **Public** sites | SharePoint Admin | `[ ]` |
| 4a.8 | Run **Microsoft Purview Data Access Governance (DAG) / SharePoint Advanced Management** oversharing reports if licensed — export results and action findings | SharePoint Admin | `[ ]` |

#### 4b — Sharing Links and External Access

| # | Check | Owner | Done |
|---|-------|-------|------|
| 4b.1 | Run a report of all **"Anyone" (anonymous) sharing links** on Finance sites — revoke any that cannot be explicitly justified and time-limited | SharePoint Admin | `[ ]` |
| 4b.2 | Run a report of all **"People in your organisation"** sharing links on Finance sites — validate each is intentional and not a legacy link left after a project ended | SharePoint Admin | `[ ]` |
| 4b.3 | Confirm **external sharing is disabled** at tenant and site level for Finance sites unless there is a documented, approved use case | SharePoint Admin | `[ ]` |
| 4b.4 | Set the **default sharing link type** for Finance sites to "Specific people" (not "Anyone" or "People in your organisation") via SharePoint Admin Centre | SharePoint Admin | `[ ]` |
| 4b.5 | Confirm **link expiry policies** are enforced for any sharing links that must remain active | SharePoint Admin | `[ ]` |

#### 4c — OneDrive for Business

| # | Check | Owner | Done |
|---|-------|-------|------|
| 4c.1 | Run a report of Finance users' OneDrive accounts that have items shared with users outside their team or outside the organisation | SharePoint Admin | `[ ]` |
| 4c.2 | Confirm Finance users have not stored regulated data (payroll, client records) in personal OneDrive without appropriate controls — remind users of data classification policy | SharePoint Admin / DWP | `[ ]` |
| 4c.3 | Confirm OneDrive Known Folder Move (KFM) is enabled for all Finance devices so data is captured in managed OneDrive rather than local drives | Endpoint/DWP | `[ ]` |

#### 4d — Sign-off

| # | Check | Owner | Done |
|---|-------|-------|------|
| 4d.1 | Document all remediation actions taken, with before/after permission states, and retain as audit evidence | SharePoint Admin | `[ ]` |
| 4d.2 | Obtain **formal written sign-off** from the Finance Director (or nominated data owner) confirming the permissions audit is complete and residual risks are accepted | Finance Director | `[ ]` |
| 4d.3 | Obtain **formal written sign-off** from the Information Security team confirming the environment is acceptable for Copilot deployment | InfoSec | `[ ]` |

---

## Section 5 — Sensitivity Labelling

| # | Check | Owner | Done |
|---|-------|-------|------|
| 5.1 | Confirm **Microsoft Purview sensitivity labels** are published and available to Finance users — at minimum: Public, Internal, Confidential, Highly Confidential | InfoSec / Purview Admin | `[ ]` |
| 5.2 | Confirm a **mandatory labelling policy** is enforced for Finance users in Microsoft 365 Apps (Word, Excel, PowerPoint, Outlook) — no document saved without a label | InfoSec / Purview Admin | `[ ]` |
| 5.3 | Confirm **auto-labelling policies** are configured in Purview to detect and label documents containing financial PII (payroll data, account numbers, NI numbers, client financial records) | InfoSec / Purview Admin | `[ ]` |
| 5.4 | Confirm **Highly Confidential** or equivalent label applies encryption that restricts access to named individuals or groups (not all Finance) for M&A and board pack content | InfoSec / Purview Admin | `[ ]` |
| 5.5 | Confirm Copilot is configured to **honour sensitivity labels** — validate that Copilot-generated content inherits the highest label of its source documents | InfoSec / Purview Admin | `[ ]` |
| 5.6 | Confirm **Copilot interaction data** (prompts and responses) is covered by your Purview Communication Compliance or audit log retention policy | InfoSec / Purview Admin | `[ ]` |
| 5.7 | Run a baseline scan of Finance SharePoint sites using Purview Content Explorer to identify unlabelled documents — set a remediation target before go-live | InfoSec / Purview Admin | `[ ]` |

---

## Section 6 — Licence Assignment

> Complete Sections 1–5 before proceeding. Licence assignment is the deployment trigger.

| # | Check | Owner | Done |
|---|-------|-------|------|
| 6.1 | Assign **Microsoft 365 Copilot licences** to Finance pilot cohort first (recommended: 10–20 users from varied Finance roles) | Licence Admin | `[ ]` |
| 6.2 | Confirm Copilot is surfacing correctly in Microsoft 365 Apps and Teams for pilot users within 24–48 hours of licence assignment | DWP / Pilot Users | `[ ]` |
| 6.3 | Validate pilot users cannot access data outside their intended scope via Copilot (spot-check with test prompts against known restricted content) | InfoSec / DWP | `[ ]` |
| 6.4 | After successful pilot sign-off, assign licences to remaining Finance users in a controlled rollout wave | Licence Admin | `[ ]` |

---

## Section 7 — End-User Communications and Enablement

| # | Check | Owner | Done |
|---|-------|-------|------|
| 7.1 | Send a **pre-launch communication** to Finance users explaining what Copilot is, when it will be enabled, and what they should do to prepare (especially: label documents, review what they have shared) | Comms / DWP | `[ ]` |
| 7.2 | Deliver a **Finance-specific Copilot training session** covering: how Copilot accesses data, responsible use, prompt writing for financial tasks, and what not to ask Copilot to do with sensitive data | L&D / DWP | `[ ]` |
| 7.3 | Publish a **Finance acceptable use guide** for Copilot, covering: approved use cases, prohibited use cases (e.g. do not use Copilot to draft external client communications without review), data handling obligations | InfoSec / Comms | `[ ]` |
| 7.4 | Brief Finance managers separately on Copilot's data access model — managers must understand that Copilot will surface data any of their team members can access | L&D / DWP | `[ ]` |
| 7.5 | Establish a **feedback and incident reporting channel** for Finance Copilot users (e.g. dedicated Teams channel or ServiceNow category) so unexpected data surfacing is reported and investigated promptly | DWP | `[ ]` |
| 7.6 | Schedule a **30-day post-deployment review** to assess adoption, gather feedback, and review any permission or data access issues reported | DWP / InfoSec | `[ ]` |

---

## Sign-off Record

| Role | Name | Date | Signature |
|------|------|------|-----------|
| DWP Lead Engineer | | | |
| SharePoint / M365 Admin | | | |
| Information Security | | | |
| Finance Director (Data Owner) | | | |
| Programme / Change Manager | | | |

---

## Appendix — Key References

- [Microsoft 365 Copilot requirements](https://learn.microsoft.com/en-us/microsoft-365-copilot/microsoft-365-copilot-requirements)
- [Microsoft Purview Data Access Governance](https://learn.microsoft.com/en-us/purview/data-access-governance-sharepoint)
- [SharePoint Advanced Management — Oversharing reports](https://learn.microsoft.com/en-us/sharepoint/advanced-management)
- [Sensitivity labels and Microsoft 365 Copilot](https://learn.microsoft.com/en-us/purview/sensitivity-labels-copilot)
- [Microsoft Copilot adoption hub](https://adoption.microsoft.com/en-us/copilot/)
- DWP AI Personal Usage Charter — see `personal-ai-usage-charter-dwp-endpoint.md` in this workspace
