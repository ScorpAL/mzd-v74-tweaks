# Hello command

Copy this folder to usb/tweaks/hello/. The launcher discovers it automatically and
shows Run. Status is read-only. It uses the same shared manifest reader as patch workers and needs no build
step. Keep settings only in manifest.conf.

This remains a current stateless command example: commands execute from USB and
are not saved as installed packages. Print the command result on stdout; the
launcher owns Run in progress/Run completed status. No progress preamble is needed.
