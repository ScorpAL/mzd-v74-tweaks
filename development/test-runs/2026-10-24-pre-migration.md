# Physical CMU evidence before this migration

- Date: 2026-10-24
- Type: physical CMU, firmware 74.00.324
- Source: earlier standalone worker 0.7.1 and styled installer package
- Exact vehicle package commit: not recorded; this is limited historical evidence

The styled menu displayed and allowed installation of SSH. SSH install returned
0, status reported installed, and an independent password login on port 22
succeeded as cmu UID 0. Uninstall returned 0 and status uninstalled. The original
stage_wifi.sh checksum was restored, port 22 and its firewall rule disappeared,
password overlay and service files were removed, and root/resources were read-only.
A subsequent menu installation again allowed login on port 22, including after
the USB was removed. Reboot persistence was not tested.

This does NOT validate the new shared-library layout or four-state contract.
Those changes require a fresh physical run. The temporary diagnostic SSH server
is not included in this repository's runnable package.
