# Copilot Support Ticket Triage — Legal Team
**Date:** 2026-08-13  
**Engineer:** DWP Endpoint Support

---

## Ticket 1 — Paralegal: "I don't have access to that content" (SharePoint NDA)

**Ticket summary:** Paralegal asked Copilot to summarise a client NDA in SharePoint and received "I don't have access to that content." She has never opened the folder before and only heard about it in a meeting.

| Field | Detail |
|---|---|
| **Likely cause** | 1. **Permissions/access boundary** — She has never opened the folder; she almost certainly has no granted access to it. Copilot strictly respects SharePoint permissions and will not surface content the user cannot access directly. |
| **Fastest check** | Ask her to navigate to the file in SharePoint and try to open it manually. If she gets an "Access denied" error, the cause is confirmed. |
| **Is this actually a Copilot bug?** | **No.** Copilot is behaving correctly by honouring the access boundary. The file is not accessible to her; Copilot cannot and should not bypass that. This is not a Copilot fault. |

---

## Ticket 2 — New Associate: Copilot in Outlook can't find case emails

**Ticket summary:** A new associate who started this week says Copilot in Outlook cannot find any of the case emails they need context on.

| Field | Detail |
|---|---|
| **Likely cause** | 1. **Data indexing lag** — Microsoft 365 Search indexes new mailboxes over several days after account creation. Copilot relies on that index; emails that are not yet indexed will not be returned. 2. **License/client prerequisite issue** — The Copilot for Microsoft 365 licence may not yet have been assigned or fully provisioned for the new account. |
| **Fastest check** | Check in the Microsoft 365 Admin Center that a Copilot licence is assigned to the account, and confirm the date it was assigned. If assigned within the last 24–72 hours, indexing lag is the primary suspect. |
| **Is this actually a Copilot bug?** | **No.** Both leading causes are expected provisioning behaviours for brand-new accounts. No evidence points to a product defect. |

---

## Ticket 3 — Partner: Copilot surfaced a draft settlement from a matter not assigned to them

**Ticket summary:** A partner says Copilot summarised a draft settlement document from a matter they are not assigned to, and they were unaware they could even see that folder.

| Field | Detail |
|---|---|
| **Likely cause** | 1. **Permissions/access boundary (misconfiguration)** — Copilot only ever surfaces content the signed-in user can access. If the partner can see the document through Copilot, they already have read access to it — most likely via an overly permissive parent-folder inheritance, a broad site-member group, or a role-based permission that was not scoped correctly. |
| **Fastest check** | Check the SharePoint permissions on the settlement document and its parent folder. Look for inherited permissions or group memberships that inadvertently include the partner. |
| **Is this actually a Copilot bug?** | **No.** Copilot did not bypass permissions; the permissions were already too broad. This is a SharePoint governance / access-control issue. Escalate to the information governance or SharePoint admin team to tighten matter-level permissions. |

---

## Ticket 4 — Legal Ops Manager: All 40 Legal team members lost Copilot access this morning

**Ticket summary:** All 40 members of the Legal team lost Copilot access simultaneously this morning; it worked fine all last week.

| Field | Detail |
|---|---|
| **Likely cause** | 1. **License/client prerequisite issue** — A bulk licence change (removal, reassignment, group policy update, or subscription lapse) is the most common cause of sudden team-wide loss. Check for any admin actions overnight. 2. **Permissions/access boundary** — A group or conditional-access policy change could have removed the Legal team's entitlement. 3. **Genuine Copilot fault** — Only consider this if licence and policy checks are both clean and the Microsoft 365 Service Health Dashboard shows an active incident. |
| **Fastest check** | Open the Microsoft 365 Admin Center → Billing → Licences and confirm Copilot for Microsoft 365 licences are still assigned to the Legal team group. Also check the M365 Service Health Dashboard for any active Copilot incidents. |
| **Is this actually a Copilot bug?** | **Unclear.** A simultaneous team-wide outage could be a service incident, but an overnight licence or policy change is statistically more likely. Confirm licence state before raising a Microsoft support case. |

---

## Ticket 5 — Contract Specialist: Vague, generic answers about contract template clauses

**Ticket summary:** Copilot gives vague, generic answers when asked about clauses in the contract templates library and does not appear to read the actual documents.

| Field | Detail |
|---|---|
| **Likely cause** | 1. **Data indexing lag** — If the templates library was recently created, migrated, or had large-scale changes, the documents may not yet be fully indexed and Copilot cannot retrieve their content. 2. **Sensitivity label restriction** — If templates carry sensitivity labels that restrict processing (e.g., "Highly Confidential — No AI"), Copilot will fall back to generic responses rather than surfacing protected content. 3. **Permissions/access boundary** — The specialist may have read access to the folder listing but not to the file contents (e.g., item-level permissions). |
| **Fastest check** | Open one of the template documents directly in Word Online and use Copilot in-document (via the Copilot pane within the open document). If it works there but not from Chat, the issue is indexing or label restriction on search. |
| **Is this actually a Copilot bug?** | **No** (most likely). Generic responses when documents exist are a known symptom of unindexed or label-restricted content. No evidence rules out these explanations in favour of a product defect. |

---

*Triage principle applied: non-Copilot causes were prioritised throughout. "Genuine Copilot fault" was only considered where all other explanations were implausible.*
