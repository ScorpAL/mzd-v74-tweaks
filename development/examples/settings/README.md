# Settings example

Copy this folder to `usb/tweaks/settings-example/` in the ready-to-run package.
The launcher renders the controls from manifest.conf. Run prints the effective
values; it does not install a tweak or change log rotation. The limits here are
illustrative and must not be used as evidence of safe CMU logrotate limits.

```sh
sh installer.sh action settings-example run log_limit_mb=30 compress=false profile=medium
sh installer.sh start-run settings-example log_limit_mb=30 compress=false profile=medium
```

Invalid values are refused by the controller before the worker starts. Missing
values use the manifest defaults. The background job owns its RAM configuration
until completion. Workers use `mzd_setting name`, never source the settings file.
