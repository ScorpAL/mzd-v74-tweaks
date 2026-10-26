# SSH Wi-Fi boot experiment — 2026-10-25

Firmware: 74.00.324 EU. Local changes based on afff979; not committed or pushed.

## Vehicle evidence

- With Wi-Fi enabled, a direct `sync; reboot` restored an unchecked Wi-Fi
  checkbox and left SSH unreachable until Wi-Fi was manually enabled.
- Mazda's HMI D-Bus exposes GetInterfaceList, GetInterfaceParams and WIFI_SetMode.
  The Wi-Fi interface was 100; its enabled client mode was 1.
- Re-requesting mode 1 while already connected succeeded without losing SSH.
- A separate bounded boot helper discovered wlan0 and requested mode 1.
  After an explicitly requested reboot, its fifth attempt succeeded and SSH
  returned at the same address around one minute after reboot, without manual
  Wi-Fi activation.

## Integration

The equivalent helper is now part of the SSH supervisor payload. It starts in
the background only after the listener and firewall are ready, makes bounded
D-Bus requests and stops requesting after success or twelve attempts. The normal
SSH payload installation, byte comparison, uninstall and reset own this code;
there is no additional persistent payload file to register.

The installed service and attached USB asset were updated without restarting
the running SSH supervisor. The temporary startup hook was removed; the startup
script matches its pre-experiment version. Current worker status is installed.
The integrated version still needs its own reboot test; the successful vehicle
boot used the separate equivalent helper. Private rollback copies remain under
/data_persist/cmu-wifi-boot-test and are not part of the shipped tweak.

Root and USB mount modes were restored to read-only. Resources accepted the
read-write remount but rejected read-only restoration with EBUSY. No process was
killed and no forced unmount performed. Resources remains read-write pending
further investigation or a user-requested reboot.

## Isolated checks

The SSH supervisor suite passed with fake kernel, account, sshd and network
commands. Its added Wi-Fi assertions use a non-default interface ID, skip a USB
interface, request client mode exactly once and retain the listener through
subsequent network changes. These checks do not prove real boot timing.

## Integrated reboot verification

A subsequent user-requested `sync; reboot` returned SSH at the same address
after roughly one minute. The Wi-Fi getter returned success and client mode 1.
The separate test startup hook was absent and its RAM directory was not created.
Both root's actual relfs mount and Resources were read-only after this boot.
No Wi-Fi acceptance log was available on USB (runtime logging requires a matching
USB to already be mounted at service startup). The SSH worker contract suite
also passed all 42 isolated real-entrypoint checks.
