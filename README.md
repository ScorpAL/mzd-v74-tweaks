# CMU Tweaks

Ready-to-run USB installer for Mazda CMU tweaks. The included tweaks currently
support firmware **74.00.324**. This is the development branch, not a released 2.0.

## Use

Download this branch, extract it, and copy the **contents of `usb/`** to the USB
root, including `jci-autoupdate` and the long `.up` filename. Insert the USB drive.
The installer opens with **OK** and **Exit**. Use it only while parked and keep
power and USB connected until changes finish.

Choose a category and tweak to read its description, then select **Install**,
**Uninstall** or **Run**. Touchscreen and multicontroller navigation are supported.
The header shows CPU use and free space for System and Resources. After changes
requiring a restart, leaving the installer offers **Restart** or **Exit**.

The installer uses the CMU's existing runtime. No extra ARM program, Python,
Node.js, compilation or package assembly is required on the vehicle.

The installed tweak version is saved on the CMU so a newer USB package can still
uninstall it using the matching scripts. Old test installations made before this
mechanism must first be uninstalled using their matching previous USB package.

## Documentation

- [User guide](wiki/Home.md): setup, controls, states, backup, restore and help.
- [Included tweaks](usb/tweaks/): each folder contains its user README.
- [Development](development/README.md): all developer documentation and examples.
- [Website sources](docs/).

System tools can back up JCI, collect logs and restore original files. Restore
resets all patches on affected files and is not a factory reset. Read its
confirmation carefully. Backups and reports are stored on the USB drive.

Installer diagnostics are controlled by `logging=normal`, `logging=debug` or
`logging=off` in `usb/installer.conf`. Normal is the default; use Debug when
collecting details for a reported problem. Action reports and explicit exports
remain available with logging Off.

Vehicle checks cover the native Lua launcher, SSH lifecycle/Wi-Fi startup and
selected patches. This does not establish every tweak on every firmware;
[reviewed evidence](development/test-runs/README.md) records the tested scope.

Original repository: https://github.com/piotrmocko/mzd-v74-tweaks.
Existing authorship remains in Git history; migration is not a claim of ownership.
