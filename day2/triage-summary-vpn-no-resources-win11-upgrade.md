# Triage Summary — T-1008: VPN Connects but No Internal Resources Reachable After Win11 Upgrade

## Summary
VPN establishes a connection successfully but the user cannot reach any internal resources following a Windows 11 upgrade.

---

## Impact
- **Who:** Single user (remote worker or off-site device)
- **How many:** 1 user confirmed; if this is a common post-upgrade regression, others on the same upgrade wave may be affected — to-verify
- **Business urgency:** High — if the user is working remotely, inability to reach internal resources (intranet, shared drives, internal services) effectively blocks all work

---

## Known Facts
- VPN client connects and appears to authenticate successfully
- No internal resources are reachable after connection (scope — all resources or specific ones — to-verify)
- Issue started after a Windows 11 upgrade
- VPN client itself is running and not reporting an error (to-verify)

---

## Missing Information to Gather
1. Which VPN client and version is installed? Was it re-installed or carried over from Win10? — to-verify
2. Can the user reach any internal resource, or is it specifically certain services (e.g., file shares, intranet, internal DNS)? — helps isolate DNS vs. routing vs. firewall
3. Does `ping` or `tracert` to an internal address return anything when VPN is connected? — to-verify (do not share internal IPs or hostnames in external tools)
4. Is the network adapter showing the VPN tunnel interface in Network Settings after connecting? — to-verify
5. Were any network drivers updated or replaced during the Win11 upgrade? — to-verify
6. Is split tunnelling configured? If so, did the routing table change post-upgrade? — to-verify
7. Has a full device reboot been performed after the upgrade and after VPN client reinstallation?

---

## Likely Category
**Endpoint / Network — VPN / DNS Resolution Post-Upgrade**
Secondary possibility: network driver regression or VPN client incompatibility with Win11 build (to-verify)

---

## First Diagnostic Step
With VPN connected, ask the user to open **Command Prompt** and run:

```
ipconfig /all
```

Check whether the VPN tunnel adapter is listed and has received an internal IP address.

- If no VPN adapter IP is shown: the tunnel is not fully established despite the client showing connected — likely a driver or client compatibility issue; consider reinstalling the VPN client against the Win11-compatible version
- If a VPN adapter IP is shown: the tunnel is up but routing or DNS is broken — next step is to check DNS server addresses assigned by the VPN adapter and test name resolution (to-verify with network team, do not share internal config details externally)
- Do not share IP ranges, hostnames, or VPN gateway addresses when escalating via external or public tools

---

*Triage produced: 2026-08-04 | Analyst review required before action*
