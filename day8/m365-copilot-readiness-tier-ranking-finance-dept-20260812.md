# Microsoft 365 Copilot Readiness — Tier Ranking
**Organisation:** [Financial Services Company]
**Department:** Finance (~200 users)
**Prepared by:** DWP Engineer
**Date:** 2026-08-12
**Companion document:** `m365-copilot-readiness-checklist-finance-dept-20260812.md`

---

## Tier Definitions

| Tier | Label | Meaning |
|------|-------|---------|
| **T1** | MUST complete before rollout | Blocking. Proceeding without these creates either a technical failure or a material data/compliance risk that cannot be tolerated. Copilot licences must not be assigned until all T1 items are resolved. |
| **T2** | SHOULD complete before rollout | High risk if skipped. Not a hard technical blocker, but skipping creates a meaningful probability of a security incident, user trust failure, or compliance finding within the first 30 days. |
| **T3** | CAN complete during or after rollout | Lower risk. Valuable improvements that can be iterated post-launch without materially increasing the probability of a serious incident. |

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

These items are non-negotiable gates. If any remain incomplete, do not proceed to licence assignment.

### From Section 1 — Licensing
| Ref | Item |
|-----|------|
| 1.1 | Confirm all Finance users hold an active M365 E5 licence |
| 1.2 | Confirm no users are on E3 or legacy SKUs lacking required service plans |
| 1.3 | Confirm Copilot add-on licences have been procured for the Finance cohort |
| 1.4 | Identify and exclude shared mailboxes, service accounts, and room resources from licence scope |

> **Why T1:** Without correct base and add-on licensing, Copilot simply will not activate. These are hard technical prerequisites with no workaround.

---

### From Section 2 — Client Version
| Ref | Item |
|-----|------|
| 2.1 | Confirm all Finance devices run M365 Apps for Enterprise (not perpetual Office) |
| 2.2 | Confirm M365 Apps build meets minimum supported Copilot version |
| 2.3 | Identify and remediate devices below minimum build before pilot |
| 2.5 | Confirm Teams desktop client is on new Teams |

> **Why T1:** Copilot features are not surfaced in unsupported client builds. Devices on perpetual Office or old build channels will silently fail to show Copilot UI. Remediating post-rollout creates a fragmented experience and a support burden.

---

### From Section 3 — Identity and MFA
| Ref | Item |
|-----|------|
| 3.1 | Confirm all Finance users authenticate via Entra ID |
| 3.2 | Confirm MFA is enforced for all Finance users via Conditional Access |
| 3.3 | Confirm no Finance users are excluded from MFA CA policies |
| 3.4 | Confirm legacy authentication protocols are blocked for Finance accounts |
| 3.6 | Confirm all Finance users have completed MFA registration |

> **Why T1:** Copilot operates under the user's identity token. An account without MFA that is compromised gives an attacker Copilot access to everything that user can reach — in this Finance context, that includes payroll, board packs, and M&A documents. Legacy auth bypasses Conditional Access entirely.

---

### From Section 4 — Permissions and Oversharing *(entire section)*
| Ref | Item |
|-----|------|
| 4a.1–4a.8 | Full SharePoint site and library permissions audit |
| 4b.1–4b.5 | Sharing links and external access remediation |
| 4c.1–4c.2 | OneDrive oversharing review |
| 4d.1–4d.3 | Documented remediation evidence and dual sign-off |

> **See detailed justification section below — this is the most critical T1 block.**

---

### From Section 5 — Sensitivity Labelling
| Ref | Item |
|-----|------|
| 5.1 | Confirm sensitivity labels are published and available to Finance users |
| 5.2 | Confirm mandatory labelling policy is enforced in M365 Apps for Finance |
| 5.5 | Confirm Copilot honours sensitivity labels and generated content inherits source labels |

> **Why T1:** Without mandatory labelling enforced before Copilot is live, users may ask Copilot to summarise or repackage Highly Confidential documents into new files that carry no label — creating unlabelled, uncontrolled copies of regulated content. Label inheritance by Copilot-generated outputs must be confirmed to work before users begin prompting at scale.

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

These are not hard technical blockers but represent elevated probability of a security or operational incident in the near term if deferred.

| Ref | Item | Risk if deferred |
|-----|------|-----------------|
| 1.5 | Billing/procurement approval in place | Financial governance failure; licences may be recalled |
| 2.4 | Update channel enforced via policy (not user-managed) | Devices drift below minimum build post-rollout; Copilot breaks silently |
| 2.6 | Users not running M365 Apps exclusively via browser | Degraded/missing Copilot features cause user confusion and support load |
| 3.5 | Entra ID sign-in and user risk policies active for Finance | Compromised accounts detected only after damage is done |
| 3.7 | No persistent admin roles for Finance accounts; PIM in use | Privileged account compromise exposes entire tenant, not just Finance |
| 4c.3 | OneDrive KFM enabled for all Finance devices | Regulated data remains on unmanaged local drives, outside Purview scope |
| 5.3 | Auto-labelling policies for financial PII content | Existing unlabelled regulated documents remain unprotected at Copilot launch |
| 5.4 | Highly Confidential label applies encryption scoped to named individuals | M&A/board pack content is technically labelled but not access-restricted |
| 5.6 | Copilot interaction data covered by audit log retention policy | Prompt/response history not retained; forensic and compliance gaps |
| 6.1–6.3 | Pilot cohort deployment and validation (spot-check data access) | Full rollout proceeds without evidence that permission controls are working as intended |
| 7.1 | Pre-launch communication to Finance users | Users encounter Copilot without context; higher likelihood of misuse or panic at unexpected data surfacing |
| 7.3 | Finance acceptable use guide published | No documented boundary between approved and prohibited Copilot use cases |
| 7.4 | Finance managers briefed on Copilot data access model | Managers unaware that Copilot reflects their team's full permission scope — governance gap |

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

These improve the deployment but can be iterated without materially increasing near-term incident probability.

| Ref | Item | Notes |
|-----|------|-------|
| 5.7 | Baseline scan to identify unlabelled documents in Finance sites | Valuable baseline, but mandatory labelling policy (T1) prevents new unlabelled content from that point forward |
| 6.4 | Broader licence rollout beyond pilot cohort | By definition post-pilot; sequence is correct |
| 7.2 | Finance-specific Copilot training session | Can be delivered in first weeks of rollout; pilot users provide real examples to train with |
| 7.5 | Feedback and incident reporting channel established | Should be ready at pilot launch; acceptable if formalised during early rollout |
| 7.6 | 30-day post-deployment review | Scheduled activity after rollout by design |

---

## Why the Permissions and Oversharing Audit Belongs in Tier 1

### The core argument

Licensing and client version checks are simpler to verify, and that simplicity is precisely why they do not need elevated priority — a failed licence assignment or an unsupported client build produces an obvious, immediate, recoverable failure. Copilot does not appear. The user raises a ticket. The engineer fixes it. No data is exposed.

A permissions failure produces the opposite: **Copilot works perfectly, and that is the problem.**

### What Copilot actually does with permissions

Microsoft 365 Copilot does not have its own access control layer. It queries Microsoft Graph on behalf of the authenticated user and returns content that user is already permitted to see. It does not check whether the user *should* have access, only whether they *do*. If a Finance analyst has read access to the CEO's board pack because a 2019 migration set a SharePoint group incorrectly, Copilot will summarise that board pack when the analyst asks a relevant question — without any warning, without any audit trail visible to the data owner, and without any error.

### Why the 2019 migration inheritance makes this uniquely high risk

Permissions inherited from a legacy migration and never audited carry specific failure patterns:

- **Ghost memberships:** Users who changed roles or left the organisation remain in SharePoint groups from the old system. Copilot will respond to their successor's prompts using the predecessor's access scope.
- **Over-broad migration groups:** Migration tooling frequently maps source system permission tiers to broad Entra groups (e.g. "Finance_All") to avoid broken access. These groups are never trimmed post-migration because everything works and no one is blocked. Seven years later, "Finance_All" may include payroll managers, M&A analysts, graduate trainees, and IT support accounts.
- **Broken inheritance from restructuring:** Folders and libraries that were reorganised post-migration may have permission overrides that grant access well beyond the intended audience, invisible at site level.
- **No institutional memory:** The engineers who ran the 2019 migration may not be available. There is no documented baseline to compare against. The audit starts from zero.

### The asymmetry of discovery

If a misconfigured permission is discovered pre-Copilot, it is a SharePoint governance finding. It is fixed quietly.

If the same misconfiguration is discovered because a Finance analyst mentions in a meeting that "Copilot summarised something that looked like an M&A target list," it is a potential breach notification event under UK GDPR Article 33, a reportable incident to the FCA under SYSC 13 (operational risk), and a significant reputational event for the Finance Director who signed off on the deployment.

### The remediation window

Oversharing remediation on a large, long-standing SharePoint estate takes time — permission exports, review cycles, approval from data owners to remove access, testing that legitimate workflows are not broken. This work cannot be parallelised with Copilot rollout because the rollout is the deadline. Licensing checks and client version checks each take hours. A permissions audit for a Finance estate with 7 years of unreviewed inheritance is measured in weeks.

Starting the permissions audit first — before licensing is even procured — is the correct sequencing. Everything else can catch up.

### Summary table

| Factor | Licensing / Client Version | Permissions Audit |
|--------|---------------------------|-------------------|
| Failure mode | Copilot does not appear — visible, recoverable | Copilot surfaces unauthorised data — silent, potentially irreversible |
| Detection | Immediate (user cannot find Copilot) | May not be detected until a user reports an anomaly |
| Remediation time | Hours | Weeks |
| Regulatory consequence of failure | None | UK GDPR Art. 33 notification; FCA SYSC 13 reporting obligation |
| Reversibility | Full — assign licence, update client | Partial — data already surfaced cannot be un-seen or un-retained |
| Specific risk factor for this department | Low | High — 7-year unaudited inheritance across payroll, M&A, board packs |

---

*Document end. For checklist items and acceptance criteria, refer to the companion checklist document.*
