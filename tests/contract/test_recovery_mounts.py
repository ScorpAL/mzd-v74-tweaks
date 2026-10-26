"""Exercise real recovery mount-role selection on synthetic mount tables only."""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
SHELL='C:/Program Files/Git/bin/bash.exe' if os.name=='nt' else '/bin/sh'
def bp(p):
    s=Path(p).resolve().as_posix()
    return '/'+s[0].lower()+s[2:] if len(s)>1 and s[1]==':' else s

checks=0
with tempfile.TemporaryDirectory(prefix='cmu-mount-roles-') as directory:
    base=Path(directory);table=base/'mounts';helper=base/'recovery.sh'
    helper.write_text((ROOT/'usb/lib/recovery.sh').read_text().replace('/proc/mounts',shlex.quote(bp(table))),encoding='utf-8',newline='\n')
    root='arbitrary-root-source / relfs ro 0 0\n'
    usb='/dev/anything /tmp/mnt/sda1 vfat ro 0 0\n'
    def check(name,records,target='/jci/gui/test.js',expected='/',origin='/tmp/mnt/sda1/installer'):
        global checks
        table.write_text(records,encoding='utf-8',newline='\n')
        script='. '+shlex.quote(bp(helper))+'; APP='+shlex.quote(target)+'; ROOT='+shlex.quote(origin)+'; mzd_recovery_mount'
        result=subprocess.run([SHELL,'-c',script],capture_output=True,text=True,timeout=10)
        assert result.returncode==(0 if expected else 1),(name,result.returncode,result.stdout,result.stderr)
        assert result.stdout==(expected+'\n' if expected else ''),(name,result.stdout)
        checks+=1
    # Device spelling does not establish whether a mount is an internal role.
    for device in ['/dev/ffx01p1','/dev/mmcblk0p1','/dev/mapper/vendor-root','/dev/nvme0n1p3','/dev/sdc9','vendor-root-source']:
        check('root '+device,device+' / relfs ro 0 0\n'+usb)
    for mount in ['/jci','/tmp/mnt/resources','/mnt/resources','/tmp/mnt/data_persist','/mnt/data_persist']:
        check('internal role '+mount,root+usb+'vendor-partition '+mount+' ext4 ro 0 0\n',mount+'/test.js',mount)
    for fs in ['ext2','ext3','ext4','relfs','ubifs','jffs2']:
        check('root filesystem '+fs,'vendor-device / '+fs+' ro 0 0\n'+usb)
    for fs in ['tmpfs','ramfs','rootfs','proc','sysfs','devtmpfs','nfs','nfs4','cifs','vfat','exfat','unknown']:
        check('unsupported root filesystem '+fs,'vendor-device / '+fs+' ro 0 0\n'+usb,expected=None)
    for mount in ['/tmp/mnt/sdb1','/mnt/another-drive','/media/disk']:
        check('external ext4 '+mount,root+usb+'vendor-partition '+mount+' ext4 ro 0 0\n',mount+'/test.js',None)
    check('installer filesystem',root+usb.replace('vfat','ext4'),'/tmp/mnt/sda1/test.js',None)
    check('origin on otherwise allowed resource role',root+'vendor /tmp/mnt/resources ext4 ro 0 0\n','/tmp/mnt/resources/test.js',None,'/tmp/mnt/resources/installer')
    check('origin on root',root,'/jci/test.js',None,'/installer')
    # The deepest mounted filesystem is decisive, including later overmounts.
    check('USB under root',root+usb+'vendor /jci/gui ext4 ro 0 0\n',expected=None)
    check('RAM under root',root+usb+'none /jci/gui tmpfs rw 0 0\n',expected=None)
    check('escaped space in child mount',root+usb+'vendor /jci/gui/my\\040disk ext4 ro 0 0\n','/jci/gui/my disk/test.js',None)
    check('escaped source mount',root+'vendor /tmp/mnt/my\\040disk ext4 ro 0 0\n',origin='/tmp/mnt/my disk/installer')
    check('network on resources',root+usb+'server:/share /tmp/mnt/resources nfs ro 0 0\n','/tmp/mnt/resources/test.js',None)
    check('rootfs hidden by real root','rootfs / rootfs rw 0 0\n'+root+usb)
    check('root hidden by RAM',root+usb+'none / tmpfs rw 0 0\n',expected=None)
    check('backup on different mount',root+usb+'vendor /jci/gui/test.js.org ext4 ro 0 0\n',expected=None)
    check('file-level overmount',root+usb+'vendor /jci/gui/test.js ext4 ro 0 0\n',expected=None)
    check('directory prefix is not a role',root+usb+'vendor /tmp/mnt/resources-extra ext4 ro 0 0\n','/tmp/mnt/resources-extra/test.js',None)
print('RECOVERY_MOUNT_ROLES_PASSED:',checks,'read-only checks; device-independent roles, real deepest mounts, USB/RAM/network refusal.')
