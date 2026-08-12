# Analysis: DEX Startup-Performance Drop (Finance-Win11)
Date: 2026-08-12

## Ranked most-likely causes (most probable first)

### 1) Additional Defender scan policy in the new security baseline is increasing logon-time disk/CPU load
Why it fits the evidence:
- The degradation starts exactly after the 2026-08-04 02:00 baseline deployment to Finance-Win11.
- Finance-Win11 is the only group that received the policy change; IT-Win11 did not and stayed stable, which strongly supports a change-linked effect rather than environment-wide drift.
- The startup-time jump is large and sustained across subsequent days, consistent with an always-on policy overhead at sign-in/startup.

Fastest check to confirm/eliminate:
- Compare Defender policy and scan activity on a small sample of affected Finance-Win11 devices versus IT-Win11 at startup/logon windows (same hours), and verify whether new scan settings/events begin on 2026-08-04.

### 2) New startup compliance-logging script added by the baseline is extending the startup critical path
Why it fits the evidence:
- The change log explicitly says a startup script was added at the exact onset time of the regression.
- A startup script can directly add synchronous delay between login and usable desktop, matching the measured metric.
- The clean control group (IT-Win11) had no rollout and no performance shift, reinforcing a deployment-scoped startup-path change.

Fastest check to confirm/eliminate:
- On affected devices, capture script execution duration and whether it runs synchronously during user startup; temporarily disable only that startup script for a pilot subset and compare next-boot startup medians.

### 3) Combined interaction effect of both baseline additions (startup script + Defender policy) causing compounded startup delay
Why it fits the evidence:
- Both controls were introduced in the same scoped deployment event and could stack resource/sequence delays during startup.
- The sharp step-change plus persistence is compatible with cumulative overhead from two startup-adjacent controls rather than a one-time anomaly.
- No similar pattern in unaffected IT-Win11 aligns with a group-specific combined policy footprint.

Fastest check to confirm/eliminate:
- Run an A/B rollback matrix on small Finance-Win11 subsets: (A) script off only, (B) Defender policy reverted only, (C) both reverted; compare next-day median startup time deltas to isolate additive impact.
