# Triage Summary: Citrix Session Launch Failure - FinBridge

Date: 2026-08-13

## Scope Facts

- Affected pool: FinBridge-VDI-Pool-02
- Affected users: 22 of 30
- Unaffected pool: FinBridge-VDI-Pool-01

## Exact Broker Error

- Broker: Timeout waiting for machine registration response (30000ms exceeded)
- Session launch FAILED: error 1030
- No machines available in the desktop group

## Machine Catalog Registration Status

### Pool-02

- 25 machines provisioned
- 3 registered
- 22 unregistered
- 0 in maintenance mode

### Pool-01

- 20 machines provisioned
- 19 registered
- 1 unregistered

## Delivery Controller Health

### dc-vdi-02

- Citrix Broker Service: STOPPED
- Last known running: yesterday 23:40
- Windows Update installed: today 00:15
- Reboot required flag set
- Host not rebooted

### dc-vdi-01

- Citrix Broker Service: RUNNING
- Uptime: 14 days
