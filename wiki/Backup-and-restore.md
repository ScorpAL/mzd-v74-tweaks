# Backup and restore

## Backup JCI

Select **System > Backup JCI > Run**. This saves a verified JCI archive on the
connected USB under `exports/backup-jci/`. Allow about 20 to 30 minutes; keep power
on and USB connected until verification finishes. The result shows the output path.
It is a JCI file backup, not a complete firmware or personal-settings backup.

## Collect logs

Select **System > Log Collector > Run**. It copies available CMU logs to
`exports/logs-collector/` on USB. Keep the resulting folder if reporting a problem;
review logs for personal information before sharing them.

## Remove one tweak

Use the tweak's **Uninstall** button. Normal uninstall reverses that tweak and
preserves unrelated patches where possible. Use this when removing one feature.

## Restore originals

If Install is refused because a file contains an old patch, the installer may
offer **Restore original** for that one file. This is offered only when a matching
original backup can be verified and no registered tweak uses the file. Read the
warning: **all tweaks on that file will be removed**. Current and original files
are saved to USB first. Back cancels; after Restore and OK, select Install again
if you want to install the tweak. Installation is not retried automatically.

The single-file option does not remove unknown programs, services or extra files.
If registered tweaks share the file, use their normal Uninstall actions or the
broader System command described below.

**System > Restore originals** restores files from their internal `.org` backups
and removes registered tweak extras. It resets **all patches on affected files**,
including changes from other installers. It is not a factory reset.

Read the additional confirmation before selecting Run. Current files and backups
are archived on USB under `reports/diffpatch/restore-originals-.../`. Internal
`.org` backups are removed only after restoration and cleanup are verified.

Restore cannot repair unsupported firmware, missing hardware, files without a
backup or unknown extra files from another installer. Old backups are restored as
saved; they are not automatically guaranteed to be factory originals. On failure,
keep the USB and follow the displayed message. If it says **Do NOT reboot**, do not
restart the CMU until the problem has been reviewed.
