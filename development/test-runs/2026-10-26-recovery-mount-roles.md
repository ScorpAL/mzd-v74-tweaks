# Device-independent mount roles for target recovery

Date: 2026-10-26. Isolated Windows tests; no physical CMU or USB modifications.

Replaced the target-recovery device-family allowlist with explicit platform mount
roles. Root, JCI, Resources and persistent-data roles are classified by their
actual mount points and supported filesystem types. The installer source mount,
unknown nested mounts and RAM/network/FAT filesystems are excluded. Target and
backup must share the eligible mount. Package-store and registered-owner guards
remain in place.

Passed 45 read-only mount-policy cases: arbitrary root device names (including
mapper, NVMe and sd-style names), supported internal roles/filesystems, ext4 USB
targets, source/target overlap, nested mounts, overmounts, separate backup mounts,
directory-prefix confusion and escaped spaces in mount tables.

The complete recovery adapter suite passed its 64 cases with the role policy.
The existing symlink/managed-alias fixtures remain skipped on this Windows host
because creating symlinks is not permitted; they are included in Linux CI.
This follow-up changes the targeted recovery policy, not global Restore scanning.
