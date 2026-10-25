"""Developer-side reader for the same data-only manifest.conf grammar as sh/JS."""
import re

FIELDS = ('contract_version id name description version type group firmware '
          'entrypoint actions target oem_backup_md5 lock_group status_scope '
          'reboot_required requires conflicts progress confirmation refresh_all reset_entrypoint').split()
REQUIRED = set(FIELDS) - {'target', 'oem_backup_md5', 'lock_group', 'progress', 'confirmation', 'refresh_all', 'reset_entrypoint'}
ID = re.compile(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
VERSION = re.compile(r'^[0-9]+\.[0-9]+\.[0-9]+$')

def parse(text):
    values = {}
    for line in text.split('\n'):
        line = line.removesuffix('\r')
        if any(ord(c) < 32 or ord(c) == 127 for c in line):
            raise ValueError('Control characters are not allowed.')
        if not line.strip() or line.startswith('#'):
            continue
        if '=' not in line:
            raise ValueError('Expected KEY=VALUE.')
        key, value = line.split('=', 1)
        if key not in FIELDS:
            raise ValueError('Unknown manifest field: ' + key)
        if key in values:
            raise ValueError('Duplicate manifest field: ' + key)
        values[key] = value
    if REQUIRED - values.keys():
        raise ValueError('Missing fields: ' + ', '.join(sorted(REQUIRED - values.keys())))
    if values['contract_version'] != '1' or values['entrypoint'] != 'run.sh':
        raise ValueError('Unsupported contract or entrypoint.')
    if not ID.fullmatch(values['id']) or not ID.fullmatch(values['group']):
        raise ValueError('Invalid ID/group.')
    if not values['name'] or not values['description']:
        raise ValueError('Name and description are required.')
    if not VERSION.fullmatch(values['version']) or not VERSION.fullmatch(values['firmware']):
        raise ValueError('Expected one numeric version/firmware with three components.')
    expected = 'run status' if values['type'] == 'command' else 'install uninstall status'
    if values['type'] not in ['command', 'patch', 'service', 'files'] or values['actions'] != expected:
        raise ValueError('Invalid type/actions.')
    if values['status_scope'] not in ['target-patch', 'configuration', 'payload', 'service-health']:
        raise ValueError('Invalid status scope.')
    if values['reboot_required'] not in ['true', 'false']:
        raise ValueError('Expected true/false.')
    for key in ['requires', 'conflicts']:
        if not re.fullmatch('[a-z0-9 -]*', values[key]) or any(not ID.fullmatch(x) for x in values[key].split()):
            raise ValueError('Invalid dependency list.')
        if len(values[key].split()) != len(set(values[key].split())):
            raise ValueError('Duplicate dependency ID.')
    if values['type'] != 'command':
        if not values.get('target', '').startswith('/'):
            raise ValueError('An absolute target is required.')
        if not re.fullmatch('[0-9a-f]{32}', values.get('oem_backup_md5', '')):
            raise ValueError('Invalid OEM backup checksum.')
        if not re.fullmatch('[A-Za-z0-9_-]+', values.get('lock_group', '')):
            raise ValueError('Invalid lock group.')
    if values.get('progress', 'false') not in ['true', 'false']:
        raise ValueError('Expected true/false for progress.')
    if values.get('refresh_all', 'false') not in ['true', 'false']:
        raise ValueError('Expected true/false for refresh_all.')
    if values.get('reset_entrypoint', '') not in ['', 'reset.sh']:
        raise ValueError('Reset entrypoint must be reset.sh.')
    result = dict(values)
    result['refresh_all'] = values.get('refresh_all', 'false') == 'true'
    result['progress'] = values.get('progress', 'false') == 'true'
    result['contract_version'] = 1
    for key in ['firmware', 'actions', 'requires', 'conflicts']:
        result[key] = values[key].split()
    result['reboot_required'] = values['reboot_required'] == 'true'
    return result

def read(path):
    return parse(path.read_text(encoding='utf-8'))
