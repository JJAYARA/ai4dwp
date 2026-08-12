# Copilot Support Ticket Triage (DWP)
Date: 2026-08-12

Cause categories used (only):
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault

## Ticket Outcomes

| ID | Likely cause (ranked, most probable first) | Fastest check | Is this actually a Copilot bug? |
|---|---|---|---|
| 1 | 1) permissions/access boundary 2) data indexing lag 3) sensitivity label restriction 4) license/client prerequisite issue 5) guest/external sharing limitation 6) genuine Copilot fault | Confirm the board pack is in a location Copilot can index and the user has direct access (not just a temporary/view-only pathway). | **No**. "I can see it" does not guarantee Copilot retrieval eligibility; access scope/indexability mismatches are more common than product defects. |
| 2 | 1) data indexing lag 2) license/client prerequisite issue 3) permissions/access boundary 4) sensitivity label restriction 5) guest/external sharing limitation 6) genuine Copilot fault | Check account age/onboarding timing and whether mailbox/activity has had enough time to index since start date (yesterday). | **No**. New-hire recency strongly points to indexing/onboarding delay, not a Copilot defect. |
| 3 | 1) sensitivity label restriction 2) permissions/access boundary 3) license/client prerequisite issue 4) data indexing lag 5) guest/external sharing limitation 6) genuine Copilot fault | Check the salary spreadsheet's sensitivity label/policy and whether policy blocks Copilot processing. | **No**. The explicit message "I don't have access" and HR salary context fit policy/label restrictions. |
| 4 | 1) guest/external sharing limitation 2) permissions/access boundary 3) sensitivity label restriction 4) data indexing lag 5) license/client prerequisite issue 6) genuine Copilot fault | Verify whether the contract is only available through an external guest link from another tenant/org. | **No**. Cross-org guest-link scenarios are a known boundary for retrieval scope. |
| 5 | 1) license/client prerequisite issue 2) permissions/access boundary 3) genuine Copilot fault 4) data indexing lag 5) sensitivity label restriction 6) guest/external sharing limitation | Check whether Finance users still have the required Copilot license/service plan enabled this morning. | **Unclear**. A whole-team sudden outage is often licensing/assignment/client prerequisite drift; mark as potential platform issue only if entitlement and client checks are clean. |
| 6 | 1) permissions/access boundary 2) data indexing lag 3) sensitivity label restriction 4) license/client prerequisite issue 5) guest/external sharing limitation 6) genuine Copilot fault | Confirm the manager currently has effective permissions on that folder/file path. | **No**. This behavior is consistent with Copilot honoring existing access rights, even when users forget they have them. |
| 7 | 1) license/client prerequisite issue 2) permissions/access boundary 3) data indexing lag 4) sensitivity label restriction 5) guest/external sharing limitation 6) genuine Copilot fault | Verify the analyst account has active Copilot entitlement and is on a supported, signed-in client build. | **Unclear**. Broadly generic answers across all internal content usually indicate setup/entitlement/access posture, not immediate evidence of a core defect. |
| 8 | 1) permissions/access boundary 2) license/client prerequisite issue 3) guest/external sharing limitation 4) data indexing lag 5) sensitivity label restriction 6) genuine Copilot fault | Check whether delegated/shared mailbox calendar permissions are explicitly granted for Copilot-retrievable access, not just UI delegation. | **No**. Shared mailbox/delegation boundaries are commonly permission-model issues rather than Copilot bugs. |

## Triage Principle Applied
- Defaulted to non-Copilot causes first.
- Kept genuine Copilot fault as last resort unless evidence clearly eliminates policy, entitlement, access, and scope constraints.
