# Restore originals and reset hooks

Local isolated evidence only. Vehicle validation is pending.

Passed locally: 14 restore scenarios, 201 existing worker checks, 22 manifest
reader checks, 14 export entrypoint checks, actual SSH supervisor behavior tests,
installer UI/transport assertions and repository validation. On Windows the invalid
filename case injects the refusal marker; Linux CI uses an actual newline filename.

Real restore entrypoint and SSH reset hook exercised with synthetic internal/USB/
navigation mounts, source files, OEM hashes and command guards. Service stop is
stubbed in this suite; actual supervisor teardown is tested separately by
`test_ssh_service.py`. Cases cover successful known and uncatalogued restores,
missing target/payload files, OEM mismatch, unknown/changed extras, archive/write/
rollback/deletion failures, empty scope and unsupported firmware. Test archives
are inspected and navigation files are checked unchanged; watchdog/mount/locks
are verified after each run.

UI assertions cover confirm/cancel, no early worker execution, full status refresh
and repair guidance for broken/unavailable patches. No real vehicle file or
service was restored/deleted during these checks.

Vehicle follow-up: use reviewed recoverable test files first, inspect USB archives
and .org removal, verify SSH supervisor/account/firewall teardown and normal UI
return, then validate reinstall creates a fresh OEM .org. Do not describe this as
a complete rollback of unknown installers or a factory reset.
