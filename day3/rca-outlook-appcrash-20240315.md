# Root Cause Analysis (RCA): Outlook Application Crash

## Incident Summary
- **Application:** Microsoft Outlook (`OUTLOOK.EXE`)
- **Primary host context:** Windows 11 endpoint (build family 22621)
- **Incident date:** 2024-03-15
- **User impact:** Outlook terminated unexpectedly at least twice within minutes, interrupting email and calendar access.
- **Scope of evidence analyzed:** Four Application log records supplied in the incident brief.

## Event ID Explanations

### Event ID 1000 - Application Error
- Records that an application process crashed or faulted.
- Captures core crash telemetry including:
  - Faulting process name/version (`OUTLOOK.EXE 16.0.17126.20132`)
  - Faulting module (`KERNELBASE.dll`)
  - Exception code (`0xc0000005`)
  - Fault offset (instruction offset where fault occurred)
  - Process ID, start time, and binary paths
- In this incident, Event 1000 appears twice, indicating repeated crash behavior.

### Event ID 1001 - Windows Error Reporting (WER)
- Records Windows Error Reporting classification/submission metadata after a crash.
- Includes fault bucket and event signature type (for grouping similar failures across systems).
- In this case:
  - `Event Name: APPCRASH`
  - `Fault bucket 1847362910, type 4`
- This supports that Windows categorized the failure as a standard application crash and attempted/queued reporting workflow.

### Event ID 1026 - .NET Runtime
- Records unhandled .NET runtime exceptions that terminate the process.
- Typically appears when managed (.NET) code in the process throws an exception that is not caught.
- In this case:
  - `System.AccessViolationException`
  - Process terminated due to unhandled exception
- This indicates memory access violation conditions propagated through .NET runtime handling inside Outlook process context.

## Reconstructed Sequence of Events (Plain English)
1. Outlook started at **09:13:44**.
2. At **09:14:22**, Outlook crashed (Event 1000). Crash metadata shows `0xc0000005` (access violation) with `KERNELBASE.dll` as the faulting module.
3. At **09:17:45**, Outlook crashed again with the same signature (Event 1000), strongly suggesting the same trigger reoccurred after restart/use.
4. At **09:18:01**, Windows Error Reporting logged APPCRASH bucketing (Event 1001), classifying the repeated crash pattern.
5. At **09:18:05**, .NET Runtime logged an unhandled `System.AccessViolationException` (Event 1026), confirming process termination due to unmanaged/invalid memory access surfaced into runtime exception handling.

## Most Likely Cause of the Crash
**Most likely cause:** recurring memory-access violation condition in Outlook execution path (likely add-in/integration or corrupted runtime interaction), causing `OUTLOOK.EXE` to fault with exception `0xc0000005` and terminate.

### Evidence from Events
- Repeated identical crash signature in Event 1000:
  - Same app version: `16.0.17126.20132`
  - Same faulting module: `KERNELBASE.dll`
  - Same exception code: `0xc0000005`
  - Same fault offset: `0x000000000003a4b2`
- Event 1026 confirms unhandled `System.AccessViolationException`, consistent with memory access violation.
- Event 1001 APPCRASH bucketing indicates this is a repeatable crash class rather than a one-off shutdown.

## Root Cause Statement
**Primary root cause:** Outlook encountered an unhandled access violation (memory access fault) during normal execution, resulting in process termination.

**Contributing factors (most probable):**
- A repeatable trigger path exists (evidenced by same fault signature within ~3.5 minutes).
- The fault bubbles through runtime layers as an unhandled exception (`System.AccessViolationException`).
- No evidence in supplied logs of OS-wide instability at the same timestamp; signal is application-path specific.

## 5 Whys Analysis

### Problem
Outlook repeatedly crashed, disrupting end-user productivity.

1. **Why did Outlook crash?**
   - Because the process hit an access violation (`0xc0000005`) and terminated.
2. **Why was there an access violation?**
   - A code path attempted invalid memory access during Outlook runtime execution (shown by `KERNELBASE.dll` fault and .NET `AccessViolationException`).
3. **Why did that code path execute repeatedly?**
   - The same operating condition/trigger reoccurred after restart or resumed user activity, producing the same fault offset and signature.
4. **Why wasn't the fault recovered gracefully?**
   - The exception was unhandled at runtime (`Event 1026`), so process termination was the fail-safe behavior.
5. **Why did the incident impact the user repeatedly in a short window?**
   - Underlying trigger remained present (configuration/add-in/data interaction), so relaunching Outlook did not remove the fault condition.

## Timeline Table
| Time (2024-03-15) | Source | Event ID | What happened | Key evidence |
|---|---|---:|---|---|
| 09:13:44 | Application Error payload | (within 1000 details) | Outlook process start time | `Faulting application start time: 2024-03-15 09:13:44` |
| 09:14:22 | Application Error | 1000 | First recorded Outlook crash | `OUTLOOK.EXE`, `KERNELBASE.dll`, `0xc0000005`, offset `0x3a4b2` |
| 09:17:45 | Application Error | 1000 | Second crash with same signature | Same module, code, and offset |
| 09:18:01 | Windows Error Reporting | 1001 | Crash classified as APPCRASH | `Fault bucket 1847362910`, `Event Name: APPCRASH` |
| 09:18:05 | .NET Runtime | 1026 | Process terminated due to unhandled exception | `System.AccessViolationException` |

## Confidence and Limitations
- **Confidence level:** High for identifying crash type (access violation) and repeated signature.
- **Limitations:** No stack trace, dump file, add-in inventory, Office health telemetry, or concurrent system events were provided; exact offending component cannot be proven from these four entries alone.

## Recommended Next Actions (Technical)
1. Launch Outlook in safe mode (`outlook.exe /safe`) to test whether add-in load path is involved.
2. Review and disable non-essential COM/VSTO add-ins; re-enable one by one to isolate trigger.
3. Run Office Quick Repair, then Online Repair if recurrence persists.
4. Collect a user-mode crash dump for `OUTLOOK.EXE` on next repro and analyze call stack.
5. Validate Office channel/build currency and known issues for `16.0.17126.20132`.
6. Check mailbox profile health (new test profile) and OST integrity if issue is mailbox-action specific.

## Business Impact Summary
- User experienced repeated Outlook interruption within a short period.
- Email/calendar workflow continuity was reduced until underlying trigger is removed.
