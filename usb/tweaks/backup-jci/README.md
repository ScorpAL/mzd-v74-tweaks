# Backup JCI

Supported firmware: **74.00.324**. Select **System > Backup JCI > Run**.
Creates and verifies `jci.zip`, a backup of the JCI files, on the connected USB.
Allow about **20 to 30 minutes** and keep vehicle power on and USB connected.

The result shows the output folder under `exports/backup-jci/`. Each run creates
a separate folder; completed folders end in `-complete`. Failed runs retain an
incomplete folder and their log. Progress shows preparation, archive creation
and verification rather than a byte percentage.

Source files are left unchanged. This is not a complete firmware or personal-settings
backup, and running it does not install a tweak or restart the CMU.
