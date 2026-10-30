"""Every discovered tweak needs explicit executable contract/fixture coverage.

These tests cover the shared patch-worker implementation. New implementation
types must add their own real-entrypoint runner instead of claiming coverage.
"""
CASES = {
    'cluster-language': 'component-bundle',
    'list-beep': 'shared-patch',
    'list-loop': 'shared-patch',
    'shorter-delay': 'shared-patch',
    'main-menu-loop': 'shared-patch',
    'no-more-disclaimer': 'shared-patch',
    'backup-jci': 'export-command',
    'logs-collector': 'export-command',
    'restore-originals': 'restore-command',
    'terminal': 'terminal-command',
    'ssh': 'shared-patch',
}
