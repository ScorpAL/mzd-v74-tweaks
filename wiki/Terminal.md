# Terminal

> [!WARNING]
> The Terminal is a command line with full (root) access to the CMU. A wrong command can damage the system or leave the CMU
> unusable, and the damage may not be reversible. Open it only if you know what you are doing, and only while parked. If you
> are not sure, do not use it.

Select **System > Terminal > Run** and type on a USB keyboard.

Leave with **HOME** on the multicontroller or by typing `exit`.

Keep the USB connected: the Terminal runs from it. Its mount is usually `/tmp/mnt/sda1` or `/tmp/mnt/sdb1`, so other scripts
on it can be run from the Terminal, for example `sh some-script.sh`.

If Terminal is shown as unavailable, its details give the reason.
