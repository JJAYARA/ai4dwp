# FinBridge Service Desk - End-User Communication (Copilot Tickets)
Date: 2026-08-12

This note explains each reported issue in plain English and what to do next.

## Ticket 1 - Finance lead: Copilot will not summarize Q3 board pack in SharePoint

What this likely means:
You can open the file, but Copilot may not be able to use it yet because of how access, location, or indexing is set up.

Next steps:
1. Confirm the board pack is stored in the main SharePoint document library (not a temporary link-only location).
2. Open the file directly from SharePoint once to confirm normal access.
3. Wait a short period and try again if the file was recently added or moved.
4. If it still fails, send the exact file link and timestamp to Service Desk for access/indexing checks.

## Ticket 2 - New hire: Copilot in Outlook does not know recent emails

What this likely means:
Because your account is new, Copilot may still be catching up with mailbox and activity indexing.

Next steps:
1. Confirm you are signed in with your corporate account in Outlook.
2. Give the system more time to index recent activity after onboarding.
3. Retry with specific prompts, for example: "Summarize emails from today about onboarding".
4. If no improvement after a business day, contact Service Desk to verify licensing and mailbox readiness.

## Ticket 3 - HR manager: Copilot cannot access sensitive salary review spreadsheet

What this likely means:
The file is likely protected by sensitivity or permission rules, and Copilot is correctly respecting that boundary.

Next steps:
1. Confirm you can open the spreadsheet directly with your current account.
2. Ask your data owner or security admin to confirm the file label and policy settings.
3. Use approved HR reporting files designed for Copilot use, if available.
4. If access should be allowed, raise a policy review request through Service Desk.

## Ticket 4 - Sales rep: Copilot in Teams cannot find contract shared via guest link from another org

What this likely means:
External guest links from another organization are often outside Copilot retrieval scope.

Next steps:
1. Open the contract directly from the shared link to confirm manual access.
2. Ask the document owner to share the file through an approved internal location where permitted.
3. If cross-org collaboration is required, request guidance from Service Desk on supported sharing patterns.
4. Retry Copilot after the file is available through a supported access path.

## Ticket 5 - IT admin: Copilot stopped for whole Finance team this morning

What this likely means:
A team-wide change usually points to licensing, service plan assignment, or client prerequisite drift rather than a single-user issue.

Next steps:
1. Confirm affected users still have Copilot licenses assigned and active.
2. Check users are signed in to supported client versions.
3. Have one pilot user sign out and back in, then test again.
4. If all checks pass and the issue continues across the team, escalate to Microsoft support with timestamps and affected user list.

## Ticket 6 - Manager: Copilot summarized a file they forgot they could access

What this likely means:
Copilot can use content you already have permission to access, even if you do not remember that permission.

Next steps:
1. Review your current access to that folder and remove access if no longer needed.
2. Ask your manager or data owner to confirm least-privilege access is applied.
3. Keep sensitive folders restricted to only required staff.
4. Contact Service Desk if you want a formal access review.

## Ticket 7 - Analyst: Copilot gives generic answers and seems to ignore internal SharePoint content

What this likely means:
This usually indicates setup or entitlement gaps, or limited access scope, rather than a product bug.

Next steps:
1. Confirm your Copilot license is active on your account.
2. Confirm you are signed into supported Office apps with the same corporate identity.
3. Test Copilot against one known internal file you can open directly.
4. If results are still generic, provide example prompts to Service Desk for deeper tenant/access checks.

## Ticket 8 - Executive assistant: Copilot in Outlook cannot see shared mailbox calendar

What this likely means:
Shared mailbox delegation in Outlook UI does not always mean Copilot has equivalent retrievable access.

Next steps:
1. Confirm delegated calendar permissions are explicitly assigned, not just auto-mapped behavior.
2. Verify you can open the shared mailbox calendar directly in Outlook.
3. Ask Service Desk to validate delegated permission model for Copilot scenarios.
4. Use the director's primary mailbox workflow where policy requires it.

## Summary for End Users

Most cases are caused by access scope, indexing delay, sharing boundaries, or licensing/setup prerequisites. These are usually configuration and policy issues, not a Copilot product defect. Service Desk can help confirm entitlement, permissions, and supported sharing patterns where needed.
