Symptom : Three Windows 11 machines on Floor 3 in OU=Finance could not process Group Policy during the 07:40-07:55 incident window. The affected machine logs showed Group Policy processing failures and no network connectivity to a domain controller.

Cause : The verified root cause was that the Floor 3 DHCP scope still referenced the old decommissioned DNS server. Affected clients received DNS server 10.10.3.250, which prevented reliable domain controller discovery and SYSVOL access.

Scope : The impact was limited to three Windows 11 machines on Floor 3 in OU=Finance. One Finance control machine, DESKTOP-FB029, was unaffected and processed Group Policy successfully with the correct DNS server 10.10.0.10.

Workaround : Update the Floor 3 DHCP scope to advertise 10.10.0.10 only, renew the affected DHCP leases, and then retest Group Policy processing. This restored service in the incident.

Permanent fix: Remove the decommissioned DNS server from the Floor 3 DHCP scope and keep the scope aligned to the approved central DNS server list. After the correction, Group Policy updates were confirmed working again.

How to spot it: Look for Netlogon Event 5719, GroupPolicy Events 1058, 1030, and 1129, and DNS Client Event 1014 on the affected machine. The DHCP Client Event 50036 showing DNS server 10.10.3.250 and the GroupPolicy Event 1500 success on DESKTOP-FB029 are the key signals from this incident.
