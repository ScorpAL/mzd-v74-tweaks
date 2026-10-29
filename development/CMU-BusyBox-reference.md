# CMU BusyBox applet reference

Rules and known limits are in [CMU BusyBox](CMU-BusyBox.md).

Below is the help text of each of the 274 applets of the BusyBox on the CMU, `BusyBox v1.19.2 (2020-02-14 18:04:06 JST)`, as
`APPLET --help` prints it, where `APPLET` is the name of the applet (for example `grep --help`). The text
is unchanged except that the first line, the BusyBox version banner, is left out.

> [!NOTE]
> `--help` lists the options of an applet, but not always every option it accepts: for example `grep -a`,
> `diff -u` and `xargs -E` are accepted although their `--help` does not show them. Do not rely on an option
> that is not listed; it may be accepted and do nothing.

## Index

- **`[`** [`[`](#a-_) · [`[[`](#a-__)

- **A** [`add-shell`](#a-add_shell) · [`addgroup`](#a-addgroup) · [`adduser`](#a-adduser) · [`adjtimex`](#a-adjtimex) · [`arp`](#a-arp) · [`arping`](#a-arping) · [`ash`](#a-ash) · [`awk`](#a-awk)

- **B** [`base64`](#a-base64) · [`basename`](#a-basename) · [`blkid`](#a-blkid) · [`blockdev`](#a-blockdev) · [`brctl`](#a-brctl) · [`bunzip2`](#a-bunzip2) · [`bzcat`](#a-bzcat) · [`bzip2`](#a-bzip2)

- **C** [`cal`](#a-cal) · [`cat`](#a-cat) · [`catv`](#a-catv) · [`chattr`](#a-chattr) · [`chgrp`](#a-chgrp) · [`chmod`](#a-chmod) · [`chown`](#a-chown) · [`chpasswd`](#a-chpasswd) · [`chroot`](#a-chroot) · [`chrt`](#a-chrt) · [`chvt`](#a-chvt) · [`cksum`](#a-cksum) · [`clear`](#a-clear) · [`cmp`](#a-cmp) · [`comm`](#a-comm) · [`cp`](#a-cp) · [`cpio`](#a-cpio) · [`cryptpw`](#a-cryptpw) · [`cttyhack`](#a-cttyhack) · [`cut`](#a-cut)

- **D** [`date`](#a-date) · [`dd`](#a-dd) · [`deallocvt`](#a-deallocvt) · [`delgroup`](#a-delgroup) · [`deluser`](#a-deluser) · [`depmod`](#a-depmod) · [`devmem`](#a-devmem) · [`df`](#a-df) · [`dhcprelay`](#a-dhcprelay) · [`diff`](#a-diff) · [`dirname`](#a-dirname) · [`dmesg`](#a-dmesg) · [`dnsdomainname`](#a-dnsdomainname) · [`dos2unix`](#a-dos2unix) · [`du`](#a-du) · [`dumpkmap`](#a-dumpkmap) · [`dumpleases`](#a-dumpleases)

- **E** [`echo`](#a-echo) · [`ed`](#a-ed) · [`egrep`](#a-egrep) · [`eject`](#a-eject) · [`env`](#a-env) · [`expand`](#a-expand) · [`expr`](#a-expr)

- **F** [`false`](#a-false) · [`fbset`](#a-fbset) · [`fbsplash`](#a-fbsplash) · [`fdflush`](#a-fdflush) · [`fdformat`](#a-fdformat) · [`fdisk`](#a-fdisk) · [`fgconsole`](#a-fgconsole) · [`fgrep`](#a-fgrep) · [`find`](#a-find) · [`findfs`](#a-findfs) · [`flock`](#a-flock) · [`fold`](#a-fold) · [`free`](#a-free) · [`fsck`](#a-fsck) · [`fsync`](#a-fsync) · [`fuser`](#a-fuser)

- **G** [`getopt`](#a-getopt) · [`getty`](#a-getty) · [`grep`](#a-grep) · [`groups`](#a-groups) · [`gunzip`](#a-gunzip) · [`gzip`](#a-gzip)

- **H** [`halt`](#a-halt) · [`hd`](#a-hd) · [`hdparm`](#a-hdparm) · [`head`](#a-head) · [`hexdump`](#a-hexdump) · [`hostid`](#a-hostid) · [`hostname`](#a-hostname) · [`httpd`](#a-httpd) · [`hwclock`](#a-hwclock)

- **I** [`id`](#a-id) · [`ifconfig`](#a-ifconfig) · [`ifdown`](#a-ifdown) · [`ifenslave`](#a-ifenslave) · [`ifplugd`](#a-ifplugd) · [`ifup`](#a-ifup) · [`inetd`](#a-inetd) · [`insmod`](#a-insmod) · [`install`](#a-install) · [`ionice`](#a-ionice) · [`iostat`](#a-iostat) · [`ip`](#a-ip) · [`ipaddr`](#a-ipaddr) · [`ipcalc`](#a-ipcalc) · [`ipcrm`](#a-ipcrm) · [`ipcs`](#a-ipcs) · [`iplink`](#a-iplink) · [`iproute`](#a-iproute) · [`iprule`](#a-iprule) · [`iptunnel`](#a-iptunnel)

- **K** [`kbd_mode`](#a-kbd_mode) · [`kill`](#a-kill) · [`killall`](#a-killall) · [`killall5`](#a-killall5) · [`klogd`](#a-klogd)

- **L** [`last`](#a-last) · [`less`](#a-less) · [`linux32`](#a-linux32) · [`linux64`](#a-linux64) · [`ln`](#a-ln) · [`loadkmap`](#a-loadkmap) · [`logger`](#a-logger) · [`login`](#a-login) · [`logname`](#a-logname) · [`logread`](#a-logread) · [`losetup`](#a-losetup) · [`ls`](#a-ls) · [`lsattr`](#a-lsattr) · [`lsmod`](#a-lsmod) · [`lspci`](#a-lspci) · [`lsusb`](#a-lsusb) · [`lzop`](#a-lzop) · [`lzopcat`](#a-lzopcat)

- **M** [`makedevs`](#a-makedevs) · [`md5sum`](#a-md5sum) · [`mdev`](#a-mdev) · [`mkdir`](#a-mkdir) · [`mke2fs`](#a-mke2fs) · [`mkfifo`](#a-mkfifo) · [`mkfs.ext2`](#a-mkfs_ext2) · [`mknod`](#a-mknod) · [`mkpasswd`](#a-mkpasswd) · [`mkswap`](#a-mkswap) · [`mktemp`](#a-mktemp) · [`modinfo`](#a-modinfo) · [`modprobe`](#a-modprobe) · [`more`](#a-more) · [`mount`](#a-mount) · [`mountpoint`](#a-mountpoint) · [`mpstat`](#a-mpstat) · [`mv`](#a-mv)

- **N** [`nameif`](#a-nameif) · [`nbd-client`](#a-nbd_client) · [`nc`](#a-nc) · [`netstat`](#a-netstat) · [`nice`](#a-nice) · [`nmeter`](#a-nmeter) · [`nohup`](#a-nohup) · [`nslookup`](#a-nslookup) · [`ntpd`](#a-ntpd)

- **O** [`od`](#a-od) · [`openvt`](#a-openvt)

- **P** [`passwd`](#a-passwd) · [`patch`](#a-patch) · [`pgrep`](#a-pgrep) · [`pidof`](#a-pidof) · [`ping`](#a-ping) · [`pipe_progress`](#a-pipe_progress) · [`pkill`](#a-pkill) · [`pmap`](#a-pmap) · [`poweroff`](#a-poweroff) · [`powertop`](#a-powertop) · [`printenv`](#a-printenv) · [`printf`](#a-printf) · [`ps`](#a-ps) · [`pscan`](#a-pscan) · [`pstree`](#a-pstree) · [`pwd`](#a-pwd) · [`pwdx`](#a-pwdx)

- **R** [`rdate`](#a-rdate) · [`rdev`](#a-rdev) · [`readlink`](#a-readlink) · [`readprofile`](#a-readprofile) · [`realpath`](#a-realpath) · [`reboot`](#a-reboot) · [`remove-shell`](#a-remove_shell) · [`renice`](#a-renice) · [`reset`](#a-reset) · [`resize`](#a-resize) · [`rev`](#a-rev) · [`rm`](#a-rm) · [`rmdir`](#a-rmdir) · [`rmmod`](#a-rmmod) · [`route`](#a-route) · [`rpm`](#a-rpm) · [`rpm2cpio`](#a-rpm2cpio) · [`rtcwake`](#a-rtcwake) · [`run-parts`](#a-run_parts) · [`rx`](#a-rx)

- **S** [`script`](#a-script) · [`scriptreplay`](#a-scriptreplay) · [`sed`](#a-sed) · [`seq`](#a-seq) · [`setarch`](#a-setarch) · [`setconsole`](#a-setconsole) · [`setfont`](#a-setfont) · [`setkeycodes`](#a-setkeycodes) · [`setlogcons`](#a-setlogcons) · [`setsid`](#a-setsid) · [`sh`](#a-sh) · [`showkey`](#a-showkey) · [`slattach`](#a-slattach) · [`sleep`](#a-sleep) · [`smemcap`](#a-smemcap) · [`sort`](#a-sort) · [`split`](#a-split) · [`stat`](#a-stat) · [`strings`](#a-strings) · [`stty`](#a-stty) · [`su`](#a-su) · [`sulogin`](#a-sulogin) · [`sum`](#a-sum) · [`swapoff`](#a-swapoff) · [`swapon`](#a-swapon) · [`sync`](#a-sync) · [`sysctl`](#a-sysctl) · [`syslogd`](#a-syslogd)

- **T** [`tac`](#a-tac) · [`tail`](#a-tail) · [`tar`](#a-tar) · [`taskset`](#a-taskset) · [`tcpsvd`](#a-tcpsvd) · [`tee`](#a-tee) · [`test`](#a-test) · [`time`](#a-time) · [`timeout`](#a-timeout) · [`top`](#a-top) · [`touch`](#a-touch) · [`tr`](#a-tr) · [`traceroute`](#a-traceroute) · [`true`](#a-true) · [`tty`](#a-tty) · [`ttysize`](#a-ttysize) · [`tunctl`](#a-tunctl) · [`tune2fs`](#a-tune2fs)

- **U** [`udhcpc`](#a-udhcpc) · [`udhcpd`](#a-udhcpd) · [`umount`](#a-umount) · [`uname`](#a-uname) · [`unexpand`](#a-unexpand) · [`uniq`](#a-uniq) · [`unix2dos`](#a-unix2dos) · [`unlzop`](#a-unlzop) · [`uptime`](#a-uptime) · [`users`](#a-users) · [`usleep`](#a-usleep)

- **V** [`vconfig`](#a-vconfig) · [`vi`](#a-vi) · [`vlock`](#a-vlock) · [`volname`](#a-volname)

- **W** [`watch`](#a-watch) · [`watchdog`](#a-watchdog) · [`wc`](#a-wc) · [`wget`](#a-wget) · [`which`](#a-which) · [`who`](#a-who) · [`whoami`](#a-whoami)

- **X** [`xargs`](#a-xargs)

- **Y** [`yes`](#a-yes)

- **Z** [`zcat`](#a-zcat) · [`zcip`](#a-zcip)

<a id="a-_"></a>

## `[`

```
Usage: [ EXPRESSION ]

Check file types, compare values etc. Return a 0/1 exit code
depending on logical value of EXPRESSION
```

<a id="a-__"></a>

## `[[`

```
Usage: [[ EXPRESSION ]

Check file types, compare values etc. Return a 0/1 exit code
depending on logical value of EXPRESSION
```

<a id="a-add_shell"></a>

## `add-shell`

```
Usage: add-shell SHELL...

Add SHELLs to /etc/shells
```

<a id="a-addgroup"></a>

## `addgroup`

```
Usage: addgroup [-g GID] [USER] GROUP

Add a group or add a user to a group

	-g GID	Group id
	-S	Create a system group
```

<a id="a-adduser"></a>

## `adduser`

```
Usage: adduser [OPTIONS] USER

Add a user

	-h DIR		Home directory
	-g GECOS	GECOS field
	-s SHELL	Login shell
	-G GRP		Add user to existing group
	-S		Create a system user
	-D		Don't assign a password
	-H		Don't create home directory
	-u UID		User id
```

<a id="a-adjtimex"></a>

## `adjtimex`

```
Usage: adjtimex [-q] [-o OFF] [-f FREQ] [-p TCONST] [-t TICK]

Read and optionally set system timebase parameters. See adjtimex(2)

	-q	Quiet
	-o OFF	Time offset, microseconds
	-f FREQ	Frequency adjust, integer kernel units (65536 is 1ppm)
		(positive values make clock run faster)
	-t TICK	Microseconds per tick, usually 10000
	-p TCONST
```

<a id="a-arp"></a>

## `arp`

```
Usage: arp 
[-vn]	[-H HWTYPE] [-i IF] -a [HOSTNAME]
[-v]		    [-i IF] -d HOSTNAME [pub]
[-v]	[-H HWTYPE] [-i IF] -s HOSTNAME HWADDR [temp]
[-v]	[-H HWTYPE] [-i IF] -s HOSTNAME HWADDR [netmask MASK] pub
[-v]	[-H HWTYPE] [-i IF] -Ds HOSTNAME IFACE [netmask MASK] pub

Manipulate ARP cache

	-a		Display (all) hosts
	-s		Set new ARP entry
	-d		Delete a specified entry
	-v		Verbose
	-n		Don't resolve names
	-i IF		Network interface
	-D		Read <hwaddr> from given device
	-A,-p AF	Protocol family
	-H HWTYPE	Hardware address type
```

<a id="a-arping"></a>

## `arping`

```
Usage: arping [-fqbDUA] [-c CNT] [-w TIMEOUT] [-I IFACE] [-s SRC_IP] DST_IP

Send ARP requests/replies

	-f		Quit on first ARP reply
	-q		Quiet
	-b		Keep broadcasting, don't go unicast
	-D		Duplicated address detection mode
	-U		Unsolicited ARP mode, update your neighbors
	-A		ARP answer mode, update your neighbors
	-c N		Stop after sending N ARP requests
	-w TIMEOUT	Time to wait for ARP reply, seconds
	-I IFACE	Interface to use (default eth0)
	-s SRC_IP	Sender IP address
	DST_IP		Target IP address
```

<a id="a-ash"></a>

## `ash`

```
Usage: ash [-/+OPTIONS] [-/+o OPT]... [-c 'SCRIPT' [ARG0 [ARGS]] / FILE [ARGS]]

Unix shell interpreter
```

<a id="a-awk"></a>

## `awk`

```
Usage: awk [OPTIONS] [AWK_PROGRAM] [FILE]...

	-v VAR=VAL	Set variable
	-F SEP		Use SEP as field separator
	-f FILE		Read program from FILE
```

<a id="a-base64"></a>

## `base64`

```
Usage: base64 [-d] [FILE]

Base64 encode or decode FILE to standard output
	-d	Decode data
```

<a id="a-basename"></a>

## `basename`

```
Usage: basename FILE [SUFFIX]

Strip directory path and .SUFFIX from FILE
```

<a id="a-blkid"></a>

## `blkid`

```
Usage: blkid 

Print UUIDs of all filesystems
```

<a id="a-blockdev"></a>

## `blockdev`

```
Usage: blockdev OPTION BLOCKDEV

	--setro		Set ro
	--setrw		Set rw
	--getro		Get ro
	--getss		Get sector size
	--getbsz	Get block size
	--setbsz BYTES	Set block size
	--getsz		Get device size in 512-byte sectors
	--getsize64	Get device size in bytes
	--flushbufs	Flush buffers
	--rereadpt	Reread partition table
```

<a id="a-brctl"></a>

## `brctl`

```
Usage: brctl COMMAND [BRIDGE [INTERFACE]]

Manage ethernet bridges

Commands:
	show			Show a list of bridges
	addbr BRIDGE		Create BRIDGE
	delbr BRIDGE		Delete BRIDGE
	addif BRIDGE IFACE	Add IFACE to BRIDGE
	delif BRIDGE IFACE	Delete IFACE from BRIDGE
	setageing BRIDGE TIME		Set ageing time
	setfd BRIDGE TIME		Set bridge forward delay
	sethello BRIDGE TIME		Set hello time
	setmaxage BRIDGE TIME		Set max message age
	setpathcost BRIDGE COST		Set path cost
	setportprio BRIDGE PRIO		Set port priority
	setbridgeprio BRIDGE PRIO	Set bridge priority
	stp BRIDGE [1/yes/on|0/no/off]	STP on/off
```

<a id="a-bunzip2"></a>

## `bunzip2`

```
Usage: bunzip2 [-cf] [FILE]...

Decompress FILEs (or stdin)

	-c	Write to stdout
	-f	Force
```

<a id="a-bzcat"></a>

## `bzcat`

```
Usage: bzcat FILE

Decompress to stdout
```

<a id="a-bzip2"></a>

## `bzip2`

```
Usage: bzip2 [OPTIONS] [FILE]...

Compress FILEs (or stdin) with bzip2 algorithm

	-1..9	Compression level
	-d	Decompress
	-c	Write to stdout
	-f	Force
```

<a id="a-cal"></a>

## `cal`

```
Usage: cal [-jy] [[MONTH] YEAR]

Display a calendar

	-j	Use julian dates
	-y	Display the entire year
```

<a id="a-cat"></a>

## `cat`

```
Usage: cat [FILE]...

Concatenate FILEs and print them to stdout
```

<a id="a-catv"></a>

## `catv`

```
Usage: catv [-etv] [FILE]...

Display nonprinting characters as ^x or M-x

	-e	End each line with $
	-t	Show tabs as ^I
	-v	Don't use ^x or M-x escapes
```

<a id="a-chattr"></a>

## `chattr`

```
Usage: chattr [-R] [-+=AacDdijsStTu] [-v VERSION] [FILE]...

Change file attributes on an ext2 fs

Modifiers:
	-	Remove attributes
	+	Add attributes
	=	Set attributes
Attributes:
	A	Don't track atime
	a	Append mode only
	c	Enable compress
	D	Write dir contents synchronously
	d	Don't backup with dump
	i	Cannot be modified (immutable)
	j	Write all data to journal first
	s	Zero disk storage when deleted
	S	Write file contents synchronously
	t	Disable tail-merging of partial blocks with other files
	u	Allow file to be undeleted
	-R	Recurse
	-v	Set the file's version/generation number
```

<a id="a-chgrp"></a>

## `chgrp`

```
Usage: chgrp [-RhLHPcvf]... GROUP FILE...

Change the group membership of each FILE to GROUP

	-R	Recurse
	-h	Affect symlinks instead of symlink targets
	-L	Traverse all symlinks to directories
	-H	Traverse symlinks on command line only
	-P	Don't traverse symlinks (default)
	-c	List changed files
	-v	Verbose
	-f	Hide errors
```

<a id="a-chmod"></a>

## `chmod`

```
Usage: chmod [-Rcvf] MODE[,MODE]... FILE...

Each MODE is one or more of the letters ugoa, one of the
symbols +-= and one or more of the letters rwxst

	-R	Recurse
	-c	List changed files
	-v	List all files
	-f	Hide errors
```

<a id="a-chown"></a>

## `chown`

```
Usage: chown [-RhLHPcvf]... OWNER[<.|:>[GROUP]] FILE...

Change the owner and/or group of each FILE to OWNER and/or GROUP

	-R	Recurse
	-h	Affect symlinks instead of symlink targets
	-L	Traverse all symlinks to directories
	-H	Traverse symlinks on command line only
	-P	Don't traverse symlinks (default)
	-c	List changed files
	-v	List all files
	-f	Hide errors
```

<a id="a-chpasswd"></a>

## `chpasswd`

```
Usage: chpasswd [--md5|--encrypted]

Read user:password from stdin and update /etc/passwd

	-e,--encrypted	Supplied passwords are in encrypted form
	-m,--md5	Use MD5 encryption instead of DES
```

<a id="a-chroot"></a>

## `chroot`

```
Usage: chroot NEWROOT [PROG ARGS]

Run PROG with root directory set to NEWROOT
```

<a id="a-chrt"></a>

## `chrt`

```
Usage: chrt [-prfom] [PRIO] [PID | PROG ARGS]

Change scheduling priority and class for a process

	-p	Operate on PID
	-r	Set SCHED_RR class
	-f	Set SCHED_FIFO class
	-o	Set SCHED_OTHER class
	-m	Show min/max priorities
```

<a id="a-chvt"></a>

## `chvt`

```
Usage: chvt N

Change the foreground virtual terminal to /dev/ttyN
```

<a id="a-cksum"></a>

## `cksum`

```
Usage: cksum FILES...

Calculate the CRC32 checksums of FILES
```

<a id="a-clear"></a>

## `clear`

```
Usage: clear 

Clear screen
```

<a id="a-cmp"></a>

## `cmp`

```
Usage: cmp [-l] [-s] FILE1 [FILE2 [SKIP1 [SKIP2]]]

Compare FILE1 with FILE2 (or stdin)

	-l	Write the byte numbers (decimal) and values (octal)
		for all differing bytes
	-s	Quiet
```

<a id="a-comm"></a>

## `comm`

```
Usage: comm [-123] FILE1 FILE2

Compare FILE1 with FILE2

	-1	Suppress lines unique to FILE1
	-2	Suppress lines unique to FILE2
	-3	Suppress lines common to both files
```

<a id="a-cp"></a>

## `cp`

```
Usage: cp [OPTIONS] SOURCE DEST

Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY

	-a	Same as -dpR
	-R,-r	Recurse
	-d,-P	Preserve symlinks (default if -R)
	-L	Follow all symlinks
	-H	Follow symlinks on command line
	-p	Preserve file attributes if possible
	-f	Overwrite
	-i	Prompt before overwrite
	-l,-s	Create (sym)links
```

<a id="a-cpio"></a>

## `cpio`

```
Usage: cpio [-dmvu] [-F FILE] [-H newc] [-tio] [-p DIR] [EXTR_FILE]...

Extract or list files from a cpio archive, or
create an archive (-o) or copy files (-p) using file list on stdin

Main operation mode:
	-t	List
	-i	Extract EXTR_FILEs (or all)
	-o	Create (requires -H newc)
	-p DIR	Copy files to DIR
	-d	Make leading directories
	-m	Preserve mtime
	-v	Verbose
	-u	Overwrite
	-F FILE	Input (-t,-i,-p) or output (-o) file
	-H newc	Archive format
```

<a id="a-cryptpw"></a>

## `cryptpw`

```
Usage: cryptpw [OPTIONS] [PASSWORD] [SALT]

Crypt PASSWORD using crypt(3)

	-P,--password-fd=N	Read password from fd N
	-m,--method=TYPE	Encryption method
	-S,--salt=SALT
```

<a id="a-cttyhack"></a>

## `cttyhack`

```
Usage: cttyhack PROG ARGS

Give PROG a controlling tty if possible.
Example for /etc/inittab (for busybox init):
	::respawn:/bin/cttyhack /bin/sh
Giving controlling tty to shell running with PID 1:
	$ exec cttyhack sh
Starting interactive shell from boot shell script:
	setsid cttyhack sh
```

<a id="a-cut"></a>

## `cut`

```
Usage: cut [OPTIONS] [FILE]...

Print selected fields from each input FILE to stdout

	-b LIST	Output only bytes from LIST
	-c LIST	Output only characters from LIST
	-d CHAR	Use CHAR instead of tab as the field delimiter
	-s	Output only the lines containing delimiter
	-f N	Print only these fields
	-n	Ignored
```

<a id="a-date"></a>

## `date`

```
Usage: date [OPTIONS] [+FMT] [TIME]

Display time (using +FMT), or set time

	[-s,--set] TIME	Set time to TIME
	-u,--utc	Work in UTC (don't convert to local time)
	-R,--rfc-2822	Output RFC-2822 compliant date string
	-I[SPEC]	Output ISO-8601 compliant date string
			SPEC='date' (default) for date only,
			'hours', 'minutes', or 'seconds' for date and
			time to the indicated precision
	-r,--reference FILE	Display last modification time of FILE
	-d,--date TIME	Display TIME, not 'now'
	-D FMT		Use FMT for -d TIME conversion

Recognized TIME formats:
	hh:mm[:ss]
	[YYYY.]MM.DD-hh:mm[:ss]
	YYYY-MM-DD hh:mm[:ss]
	[[[[[YY]YY]MM]DD]hh]mm[.ss]
```

<a id="a-dd"></a>

## `dd`

```
Usage: dd [if=FILE] [of=FILE] [ibs=N] [obs=N] [bs=N] [count=N] [skip=N]
	[seek=N] [conv=notrunc|noerror|sync|fsync]

Copy a file with converting and formatting

	if=FILE		Read from FILE instead of stdin
	of=FILE		Write to FILE instead of stdout
	bs=N		Read and write N bytes at a time
	ibs=N		Read N bytes at a time
	obs=N		Write N bytes at a time
	count=N		Copy only N input blocks
	skip=N		Skip N input blocks
	seek=N		Skip N output blocks
	conv=notrunc	Don't truncate output file
	conv=noerror	Continue after read errors
	conv=sync	Pad blocks with zeros
	conv=fsync	Physically write data out before finishing

Numbers may be suffixed by c (x1), w (x2), b (x512), kD (x1000), k (x1024),
MD (x1000000), M (x1048576), GD (x1000000000) or G (x1073741824)
```

<a id="a-deallocvt"></a>

## `deallocvt`

```
Usage: deallocvt [N]

Deallocate unused virtual terminal /dev/ttyN
```

<a id="a-delgroup"></a>

## `delgroup`

```
Usage: delgroup [USER] GROUP

Delete group GROUP from the system or user USER from group GROUP
```

<a id="a-deluser"></a>

## `deluser`

```
Usage: deluser USER

Delete USER from the system
```

<a id="a-depmod"></a>

## `depmod`

```
Usage: depmod [-qfwrsv] MODULE [symbol=value]...

	-r	Remove MODULE (stacks) or do autoclean
	-q	Quiet
	-v	Verbose
	-f	Force
	-w	Wait for unload
	-s	Report via syslog instead of stderr
```

<a id="a-devmem"></a>

## `devmem`

```
Usage: devmem ADDRESS [WIDTH [VALUE]]

Read/write from physical address

	ADDRESS	Address to act upon
	WIDTH	Width (8/16/...)
	VALUE	Data to be written
```

<a id="a-df"></a>

## `df`

```
Usage: df [-Pkmhai] [-B SIZE] [FILESYSTEM]...

Print filesystem usage statistics

	-P	POSIX output format
	-k	1024-byte blocks (default)
	-m	1M-byte blocks
	-h	Human readable (e.g. 1K 243M 2G)
	-a	Show all filesystems
	-i	Inodes
	-B SIZE	Blocksize
```

<a id="a-dhcprelay"></a>

## `dhcprelay`

```
Usage: dhcprelay CLIENT_IFACE[,CLIENT_IFACE2]... SERVER_IFACE [SERVER_IP]

Relay DHCP requests between clients and server
```

<a id="a-diff"></a>

## `diff`

```
Usage: diff [-abBdiNqrTstw] [-L LABEL] [-S FILE] [-U LINES] FILE1 FILE2

Compare files line by line and output the differences between them.
This implementation supports unified diffs only.

	-a	Treat all files as text
	-b	Ignore changes in the amount of whitespace
	-B	Ignore changes whose lines are all blank
	-d	Try hard to find a smaller set of changes
	-i	Ignore case differences
	-L	Use LABEL instead of the filename in the unified header
	-N	Treat absent files as empty
	-q	Output only whether files differ
	-r	Recurse
	-S	Start with FILE when comparing directories
	-T	Make tabs line up by prefixing a tab when necessary
	-s	Report when two files are the same
	-t	Expand tabs to spaces in output
	-U	Output LINES lines of context
	-w	Ignore all whitespace
```

<a id="a-dirname"></a>

## `dirname`

```
Usage: dirname FILENAME

Strip non-directory suffix from FILENAME
```

<a id="a-dmesg"></a>

## `dmesg`

```
Usage: dmesg [-c] [-n LEVEL] [-s SIZE]

Print or control the kernel ring buffer

	-c		Clear ring buffer after printing
	-n LEVEL	Set console logging level
	-s SIZE		Buffer size
```

<a id="a-dnsdomainname"></a>

## `dnsdomainname`

```
No help available.
```

<a id="a-dos2unix"></a>

## `dos2unix`

```
Usage: dos2unix [-ud] [FILE]

Convert FILE in-place from DOS to Unix format.
When no file is given, use stdin/stdout.

	-u	dos2unix
	-d	unix2dos
```

<a id="a-du"></a>

## `du`

```
Usage: du [-aHLdclsxhmk] [FILE]...

Summarize disk space used for each FILE and/or directory.
Disk space is printed in units of 1024 bytes.

	-a	Show file sizes too
	-L	Follow all symlinks
	-H	Follow symlinks on command line
	-d N	Limit output to directories (and files with -a) of depth < N
	-c	Show grand total
	-l	Count sizes many times if hard linked
	-s	Display only a total for each argument
	-x	Skip directories on different filesystems
	-h	Sizes in human readable format (e.g., 1K 243M 2G )
	-m	Sizes in megabytes
	-k	Sizes in kilobytes (default)
```

<a id="a-dumpkmap"></a>

## `dumpkmap`

```
Usage: dumpkmap > keymap

Print a binary keyboard translation table to stdout
```

<a id="a-dumpleases"></a>

## `dumpleases`

```
Usage: dumpleases [-r|-a] [-f LEASEFILE]

Display DHCP leases granted by udhcpd

	-f,--file=FILE	Lease file
	-r,--remaining	Show remaining time
	-a,--absolute	Show expiration time
```

<a id="a-echo"></a>

## `echo`

```
Usage: echo [-neE] [ARG]...

Print the specified ARGs to stdout

	-n	Suppress trailing newline
	-e	Interpret backslash escapes (i.e., \t=tab)
	-E	Don't interpret backslash escapes (default)
```

<a id="a-ed"></a>

## `ed`

```
Usage: ed 
```

<a id="a-egrep"></a>

## `egrep`

```
No help available.
```

<a id="a-eject"></a>

## `eject`

```
Usage: eject [-t] [-T] [DEVICE]

Eject DEVICE or default /dev/cdrom

	-s	SCSI device
	-t	Close tray
	-T	Open/close tray (toggle)
```

<a id="a-env"></a>

## `env`

```
Usage: env [-iu] [-] [name=value]... [PROG ARGS]

Print the current environment or run PROG after setting up
the specified environment

	-, -i	Start with an empty environment
	-u	Remove variable from the environment
```

<a id="a-expand"></a>

## `expand`

```
Usage: expand [-i] [-t N] [FILE]...

Convert tabs to spaces, writing to stdout

	-i,--initial	Don't convert tabs after non blanks
	-t,--tabs=N	Tabstops every N chars
```

<a id="a-expr"></a>

## `expr`

```
Usage: expr EXPRESSION

Print the value of EXPRESSION to stdout

EXPRESSION may be:
	ARG1 | ARG2	ARG1 if it is neither null nor 0, otherwise ARG2
	ARG1 & ARG2	ARG1 if neither argument is null or 0, otherwise 0
	ARG1 < ARG2	1 if ARG1 is less than ARG2, else 0. Similarly:
	ARG1 <= ARG2
	ARG1 = ARG2
	ARG1 != ARG2
	ARG1 >= ARG2
	ARG1 > ARG2
	ARG1 + ARG2	Sum of ARG1 and ARG2. Similarly:
	ARG1 - ARG2
	ARG1 * ARG2
	ARG1 / ARG2
	ARG1 % ARG2
	STRING : REGEXP		Anchored pattern match of REGEXP in STRING
	match STRING REGEXP	Same as STRING : REGEXP
	substr STRING POS LENGTH Substring of STRING, POS counted from 1
	index STRING CHARS	Index in STRING where any CHARS is found, or 0
	length STRING		Length of STRING
	quote TOKEN		Interpret TOKEN as a string, even if
				it is a keyword like 'match' or an
				operator like '/'
	(EXPRESSION)		Value of EXPRESSION

Beware that many operators need to be escaped or quoted for shells.
Comparisons are arithmetic if both ARGs are numbers, else
lexicographical. Pattern matches return the string matched between
\( and \) or null; if \( and \) are not used, they return the number
of characters matched or 0.
```

<a id="a-false"></a>

## `false`

```
Usage: false 

Return an exit code of FALSE (1)
```

<a id="a-fbset"></a>

## `fbset`

```
Usage: fbset [OPTIONS] [MODE]

Show and modify frame buffer settings
```

<a id="a-fbsplash"></a>

## `fbsplash`

```
Usage: fbsplash -s IMGFILE [-c] [-d DEV] [-i INIFILE] [-f CMD]

	-s	Image
	-c	Hide cursor
	-d	Framebuffer device (default /dev/fb0)
	-i	Config file (var=value):
			BAR_LEFT,BAR_TOP,BAR_WIDTH,BAR_HEIGHT
			BAR_R,BAR_G,BAR_B
	-f	Control pipe (else exit after drawing image)
			commands: 'NN' (% for progress bar) or 'exit'
```

<a id="a-fdflush"></a>

## `fdflush`

```
Usage: fdflush DEVICE

Force floppy disk drive to detect disk change
```

<a id="a-fdformat"></a>

## `fdformat`

```
Usage: fdformat [-n] DEVICE

Format floppy disk

	-n	Don't verify after format
```

<a id="a-fdisk"></a>

## `fdisk`

```
Usage: fdisk [-ul] [-C CYLINDERS] [-H HEADS] [-S SECTORS] [-b SSZ] DISK

Change partition table

	-u		Start and End are in sectors (instead of cylinders)
	-l		Show partition table for each DISK, then exit
	-b 2048		(for certain MO disks) use 2048-byte sectors
	-C CYLINDERS	Set number of cylinders/heads/sectors
	-H HEADS
	-S SECTORS
```

<a id="a-fgconsole"></a>

## `fgconsole`

```
Usage: fgconsole 

Get active console
```

<a id="a-fgrep"></a>

## `fgrep`

```
No help available.
```

<a id="a-find"></a>

## `find`

```
Usage: find [PATH]... [OPTIONS] [ACTIONS]

Search for files and perform actions on them.
First failed action stops processing of current file.
Defaults: PATH is current directory, action is '-print'

	-follow		Follow symlinks
	-xdev		Don't descend directories on other filesystems
	-maxdepth N	Descend at most N levels. -maxdepth 0 applies
			actions to command line arguments only
	-mindepth N	Don't act on first N levels
	-depth		Act on directory *after* traversing it

Actions:
	( ACTIONS )	Group actions for -o / -a
	! ACT		Invert ACT's success/failure
	ACT1 [-a] ACT2	If ACT1 fails, stop, else do ACT2
	ACT1 -o ACT2	If ACT1 succeeds, stop, else do ACT2
			Note: -a has higher priority than -o
	-name PATTERN	Match file name (w/o directory name) to PATTERN
	-iname PATTERN	Case insensitive -name
	-path PATTERN	Match path to PATTERN
	-ipath PATTERN	Case insensitive -path
	-regex PATTERN	Match path to regex PATTERN
	-type X		File type is X (one of: f,d,l,b,c,...)
	-perm MASK	At least one mask bit (+MASK), all bits (-MASK),
			or exactly MASK bits are set in file's mode
	-mtime DAYS	mtime is greater than (+N), less than (-N),
			or exactly N days in the past
	-mmin MINS	mtime is greater than (+N), less than (-N),
			or exactly N minutes in the past
	-newer FILE	mtime is more recent than FILE's
	-inum N		File has inode number N
	-user NAME/ID	File is owned by given user
	-group NAME/ID	File is owned by given group
	-size N[bck]	File size is N (c:bytes,k:kbytes,b:512 bytes(def.))
			+/-N: file size is bigger/smaller than N
	-links N	Number of links is greater than (+N), less than (-N),
			or exactly N
	-prune		If current file is directory, don't descend into it
If none of the following actions is specified, -print is assumed
	-print		Print file name
	-print0		Print file name, NUL terminated
	-exec CMD ARG ;	Run CMD with all instances of {} replaced by
			file name. Fails if CMD exits with nonzero
	-delete		Delete current file/directory. Turns on -depth option
```

<a id="a-findfs"></a>

## `findfs`

```
Usage: findfs LABEL=label or UUID=uuid

Find a filesystem device based on a label or UUID
```

<a id="a-flock"></a>

## `flock`

```
Usage: flock [-sxun] FD|{FILE [-c] PROG ARGS}

[Un]lock file descriptor, or lock FILE, run PROG

	-s	Shared lock
	-x	Exclusive lock (default)
	-u	Unlock FD
	-n	Fail rather than wait
```

<a id="a-fold"></a>

## `fold`

```
Usage: fold [-bs] [-w WIDTH] [FILE]...

Wrap input lines in each FILE (or stdin), writing to stdout

	-b	Count bytes rather than columns
	-s	Break at spaces
	-w	Use WIDTH columns instead of 80
```

<a id="a-free"></a>

## `free`

```
Usage: free [-b/k/m/g]

Display the amount of free and used system memory
```

<a id="a-fsck"></a>

## `fsck`

```
Usage: fsck [-ANPRTV] [-C FD] [-t FSTYPE] [FS_OPTS] [BLOCKDEV]...

Check and repair filesystems

	-A	Walk /etc/fstab and check all filesystems
	-N	Don't execute, just show what would be done
	-P	With -A, check filesystems in parallel
	-R	With -A, skip the root filesystem
	-T	Don't show title on startup
	-V	Verbose
	-C n	Write status information to specified filedescriptor
	-t TYPE	List of filesystem types to check
```

<a id="a-fsync"></a>

## `fsync`

```
Usage: fsync [-d] FILE...

Write files' buffered blocks to disk

	-d	Avoid syncing metadata
```

<a id="a-fuser"></a>

## `fuser`

```
Usage: fuser [OPTIONS] FILE or PORT/PROTO

Find processes which use FILEs or PORTs

	-m	Find processes which use same fs as FILEs
	-4,-6	Search only IPv4/IPv6 space
	-s	Don't display PIDs
	-k	Kill found processes
	-SIGNAL	Signal to send (default: KILL)
```

<a id="a-getopt"></a>

## `getopt`

```
Usage: getopt [OPTIONS]

	-a,--alternative		Allow long options starting with single -
	-l,--longoptions=longopts	Long options to be recognized
	-n,--name=progname		The name under which errors are reported
	-o,--options=optstring		Short options to be recognized
	-q,--quiet			Disable error reporting by getopt(3)
	-Q,--quiet-output		No normal output
	-s,--shell=shell		Set shell quoting conventions
	-T,--test			Test for getopt(1) version
	-u,--unquoted			Don't quote the output
```

<a id="a-getty"></a>

## `getty`

```
Usage: getty [OPTIONS] BAUD_RATE[,BAUD_RATE]... TTY [TERMTYPE]

Open a tty, prompt for a login name, then invoke /bin/login

	-h		Enable hardware RTS/CTS flow control
	-L		Set CLOCAL (ignore Carrier Detect state)
	-m		Get baud rate from modem's CONNECT status message
	-n		Don't prompt for login name
	-w		Wait for CR or LF before sending /etc/issue
	-i		Don't display /etc/issue
	-f ISSUE_FILE	Display ISSUE_FILE instead of /etc/issue
	-l LOGIN	Invoke LOGIN instead of /bin/login
	-t SEC		Terminate after SEC if no login name is read
	-I INITSTR	Send INITSTR before anything else
	-H HOST		Log HOST into the utmp file as the hostname

BAUD_RATE of 0 leaves it unchanged
```

<a id="a-grep"></a>

## `grep`

```
Usage: grep [-HhnlLoqvsriwFE] [-m N] [-A/B/C N] PATTERN/-e PATTERN.../-f FILE [FILE]...

Search for PATTERN in FILEs (or stdin)

	-H	Add 'filename:' prefix
	-h	Do not add 'filename:' prefix
	-n	Add 'line_no:' prefix
	-l	Show only names of files that match
	-L	Show only names of files that don't match
	-c	Show only count of matching lines
	-o	Show only the matching part of line
	-q	Quiet. Return 0 if PATTERN is found, 1 otherwise
	-v	Select non-matching lines
	-s	Suppress open and read errors
	-r	Recurse
	-i	Ignore case
	-w	Match whole words only
	-F	PATTERN is a literal (not regexp)
	-E	PATTERN is an extended regexp
	-m N	Match up to N times per file
	-A N	Print N lines of trailing context
	-B N	Print N lines of leading context
	-C N	Same as '-A N -B N'
	-e PTRN	Pattern to match
	-f FILE	Read pattern from file
```

<a id="a-groups"></a>

## `groups`

```
Usage: groups [USER]

Print the group memberships of USER or for the current process
```

<a id="a-gunzip"></a>

## `gunzip`

```
Usage: gunzip [-cft] [FILE]...

Decompress FILEs (or stdin)

	-c	Write to stdout
	-f	Force
	-t	Test file integrity
```

<a id="a-gzip"></a>

## `gzip`

```
Usage: gzip [-cfd] [FILE]...

Compress FILEs (or stdin)

	-d	Decompress
	-c	Write to stdout
	-f	Force
```

<a id="a-halt"></a>

## `halt`

```
Usage: halt [-d DELAY] [-n] [-f] [-w]

Halt the system

	-d SEC	Delay interval
	-n	Do not sync
	-f	Force (don't go through init)
	-w	Only write a wtmp record
```

<a id="a-hd"></a>

## `hd`

```
Usage: hd FILE...

hd is an alias for hexdump -C
```

<a id="a-hdparm"></a>

## `hdparm`

```
Usage: hdparm [OPTIONS] [DEVICE]

	-a	Get/set fs readahead
	-A	Set drive read-lookahead flag (0/1)
	-b	Get/set bus state (0 == off, 1 == on, 2 == tristate)
	-B	Set Advanced Power Management setting (1-255)
	-c	Get/set IDE 32-bit IO setting
	-C	Check IDE power mode status
	-d	Get/set using_dma flag
	-D	Enable/disable drive defect-mgmt
	-f	Flush buffer cache for device on exit
	-g	Display drive geometry
	-h	Display terse usage information
	-i	Display drive identification
	-I	Detailed/current information directly from drive
	-k	Get/set keep_settings_over_reset flag (0/1)
	-K	Set drive keep_features_over_reset flag (0/1)
	-L	Set drive doorlock (0/1) (removable harddisks only)
	-m	Get/set multiple sector count
	-n	Get/set ignore-write-errors flag (0/1)
	-p	Set PIO mode on IDE interface chipset (0,1,2,3,4,...)
	-P	Set drive prefetch count
	-Q	Get/set DMA tagged-queuing depth (if supported)
	-r	Get/set readonly flag (DANGEROUS to set)
	-R	Register an IDE interface (DANGEROUS)
	-S	Set standby (spindown) timeout
	-t	Perform device read timings
	-T	Perform cache read timings
	-u	Get/set unmaskirq flag (0/1)
	-U	Unregister an IDE interface (DANGEROUS)
	-v	Defaults; same as -mcudkrag for IDE drives
	-V	Display program version and exit immediately
	-w	Perform device reset (DANGEROUS)
	-W	Set drive write-caching flag (0/1) (DANGEROUS)
	-x	Tristate device for hotswap (0/1) (DANGEROUS)
	-X	Set IDE xfer mode (DANGEROUS)
	-y	Put IDE drive in standby mode
	-Y	Put IDE drive to sleep
	-Z	Disable Seagate auto-powersaving mode
	-z	Reread partition table
```

<a id="a-head"></a>

## `head`

```
Usage: head [OPTIONS] [FILE]...

Print first 10 lines of each FILE (or stdin) to stdout.
With more than one FILE, precede each with a filename header.

	-n N[kbm]	Print first N lines
	-c N[kbm]	Print first N bytes
	-q		Never print headers
	-v		Always print headers

N may be suffixed by k (x1024), b (x512), or m (x1024^2).
```

<a id="a-hexdump"></a>

## `hexdump`

```
Usage: hexdump [-bcCdefnosvxR] [FILE]...

Display FILEs (or stdin) in a user specified format

	-b		One-byte octal display
	-c		One-byte character display
	-C		Canonical hex+ASCII, 16 bytes per line
	-d		Two-byte decimal display
	-e FORMAT_STRING
	-f FORMAT_FILE
	-n LENGTH	Interpret only LENGTH bytes of input
	-o		Two-byte octal display
	-s OFFSET	Skip OFFSET bytes
	-v		Display all input data
	-x		Two-byte hexadecimal display
	-R		Reverse of 'hexdump -Cv'
```

<a id="a-hostid"></a>

## `hostid`

```
Usage: hostid 

Print out a unique 32-bit identifier for the machine
```

<a id="a-hostname"></a>

## `hostname`

```
Usage: hostname [OPTIONS] [HOSTNAME | -F FILE]

Get or set hostname or DNS domain name

	-s	Short
	-i	Addresses for the hostname
	-d	DNS domain name
	-f	Fully qualified domain name
	-F FILE	Use FILE's content as hostname
```

<a id="a-httpd"></a>

## `httpd`

```
Usage: httpd [-ifv[v]] [-c CONFFILE] [-p [IP:]PORT] [-h HOME]
or httpd -d/-e STRING

Listen for incoming HTTP requests

	-i		Inetd mode
	-f		Don't daemonize
	-v[v]		Verbose
	-p [IP:]PORT	Bind to IP:PORT (default *:80)
	-h HOME		Home directory (default .)
	-c FILE		Configuration file (default {/etc,HOME}/httpd.conf)
	-e STRING	HTML encode STRING
	-d STRING	URL decode STRING
```

<a id="a-hwclock"></a>

## `hwclock`

```
Usage: hwclock [-r|--show] [-s|--hctosys] [-w|--systohc] [-t|--systz] [-l|--localtime] [-u|--utc] [-f|--rtc FILE]

Query and set hardware clock (RTC)

	-r	Show hardware clock time
	-s	Set system time from hardware clock
	-w	Set hardware clock from system time
	-t	Set in-kernel timezone, correct system time
		if hardware clock is in local time
	-u	Assume hardware clock is kept in UTC
	-l	Assume hardware clock is kept in local time
	-f FILE	Use specified device (e.g. /dev/rtc2)
```

<a id="a-id"></a>

## `id`

```
Usage: id [OPTIONS] [USER]

Print information about USER or the current user

	-u	User ID
	-g	Group ID
	-G	Supplementary group IDs
	-n	Print names instead of numbers
	-r	Print real ID instead of effective ID
```

<a id="a-ifconfig"></a>

## `ifconfig`

```
Usage: ifconfig [-a] interface [address]

Configure a network interface

	[add ADDRESS[/PREFIXLEN]]
	[del ADDRESS[/PREFIXLEN]]
	[[-]broadcast [ADDRESS]] [[-]pointopoint [ADDRESS]]
	[netmask ADDRESS] [dstaddr ADDRESS]
	[outfill NN] [keepalive NN]
	[hw ether|infiniband ADDRESS] [metric NN] [mtu NN]
	[[-]trailers] [[-]arp] [[-]allmulti]
	[multicast] [[-]promisc] [txqueuelen NN] [[-]dynamic]
	[mem_start NN] [io_addr NN] [irq NN]
	[up|down] ...
```

<a id="a-ifdown"></a>

## `ifdown`

```
Usage: ifdown [-anmvf] [-i FILE] IFACE...

	-a	De/configure all interfaces automatically
	-i FILE	Use FILE for interface definitions
	-n	Print out what would happen, but don't do it
		(note: doesn't disable mappings)
	-m	Don't run any mappings
	-v	Print out what would happen before doing it
	-f	Force de/configuration
```

<a id="a-ifenslave"></a>

## `ifenslave`

```
Usage: ifenslave [-cdf] MASTER_IFACE SLAVE_IFACE...

Configure network interfaces for parallel routing

	-c,--change-active	Change active slave
	-d,--detach		Remove slave interface from bonding device
	-f,--force		Force, even if interface is not Ethernet
```

<a id="a-ifplugd"></a>

## `ifplugd`

```
Usage: ifplugd [OPTIONS]

Network interface plug detection daemon

	-n		Don't daemonize
	-s		Don't log to syslog
	-i IFACE	Interface
	-f/-F		Treat link detection error as link down/link up
			(otherwise exit on error)
	-a		Don't up interface at each link probe
	-M		Monitor creation/destruction of interface
			(otherwise it must exist)
	-r PROG		Script to run
	-x ARG		Extra argument for script
	-I		Don't exit on nonzero exit code from script
	-p		Don't run script on daemon startup
	-q		Don't run script on daemon quit
	-l		Run script on startup even if no cable is detected
	-t SECS		Poll time in seconds
	-u SECS		Delay before running script after link up
	-d SECS		Delay after link down
	-m MODE		API mode (mii, priv, ethtool, wlan, iff, auto)
	-k		Kill running daemon
```

<a id="a-ifup"></a>

## `ifup`

```
Usage: ifup [-anmvf] [-i FILE] IFACE...

	-a	De/configure all interfaces automatically
	-i FILE	Use FILE for interface definitions
	-n	Print out what would happen, but don't do it
		(note: doesn't disable mappings)
	-m	Don't run any mappings
	-v	Print out what would happen before doing it
	-f	Force de/configuration
```

<a id="a-inetd"></a>

## `inetd`

```
Usage: inetd [-fe] [-q N] [-R N] [CONFFILE]

Listen for network connections and launch programs

	-f	Run in foreground
	-e	Log to stderr
	-q N	Socket listen queue (default: 128)
	-R N	Pause services after N connects/min
		(default: 0 - disabled)
```

<a id="a-insmod"></a>

## `insmod`

```
Usage: insmod [-qfwrsv] MODULE [symbol=value]...

	-r	Remove MODULE (stacks) or do autoclean
	-q	Quiet
	-v	Verbose
	-f	Force
	-w	Wait for unload
	-s	Report via syslog instead of stderr
```

<a id="a-install"></a>

## `install`

```
Usage: install [-cdDsp] [-o USER] [-g GRP] [-m MODE] [SOURCE]... DEST

Copy files and set attributes

	-c	Just copy (default)
	-d	Create directories
	-D	Create leading target directories
	-s	Strip symbol table
	-p	Preserve date
	-o USER	Set ownership
	-g GRP	Set group ownership
	-m MODE	Set permissions
```

<a id="a-ionice"></a>

## `ionice`

```
Usage: ionice [-c 1-3] [-n 0-7] [-p PID] [PROG]

Change I/O priority and class

	-c	Class. 1:realtime 2:best-effort 3:idle
	-n	Priority
```

<a id="a-iostat"></a>

## `iostat`

```
Usage: iostat [-c] [-d] [-t] [-z] [-k|-m] [ALL|BLOCKDEV...] [INTERVAL [COUNT]]

Report CPU and I/O statistics

	-c	Show CPU utilization
	-d	Show device utilization
	-t	Print current time
	-z	Omit devices with no activity
	-k	Use kb/s
	-m	Use Mb/s
```

<a id="a-ip"></a>

## `ip`

```
Usage: ip [OPTIONS] {address | route | link | tunnel | rule} {COMMAND}

ip [OPTIONS] OBJECT {COMMAND}
where OBJECT := {address | route | link | tunnel | rule}
OPTIONS := { -f[amily] { inet | inet6 | link } | -o[neline] }
```

<a id="a-ipaddr"></a>

## `ipaddr`

```
Usage: ipaddr { {add|del} IFADDR dev STRING | {show|flush}
		[dev STRING] [to PREFIX] }

ipaddr {add|delete} IFADDR dev STRING
ipaddr {show|flush} [dev STRING] [scope SCOPE-ID]
	[to PREFIX] [label PATTERN]
	IFADDR := PREFIX | ADDR peer PREFIX
	[broadcast ADDR] [anycast ADDR]
	[label STRING] [scope SCOPE-ID]
	SCOPE-ID := [host | link | global | NUMBER]
```

<a id="a-ipcalc"></a>

## `ipcalc`

```
Usage: ipcalc [OPTIONS] ADDRESS[[/]NETMASK] [NETMASK]

Calculate IP network settings from a IP address

	-b,--broadcast	Display calculated broadcast address
	-n,--network	Display calculated network address
	-m,--netmask	Display default netmask for IP
	-p,--prefix	Display the prefix for IP/NETMASK
	-h,--hostname	Display first resolved host name
	-s,--silent	Don't ever display error messages
```

<a id="a-ipcrm"></a>

## `ipcrm`

```
Usage: ipcrm [-MQS key] [-mqs id]

Upper-case options MQS remove an object by shmkey value.
Lower-case options remove an object by shmid value.

	-mM	Remove memory segment after last detach
	-qQ	Remove message queue
	-sS	Remove semaphore
```

<a id="a-ipcs"></a>

## `ipcs`

```
Usage: ipcs [[-smq] -i shmid] | [[-asmq] [-tcplu]]

	-i	Show specific resource
Resource specification:
	-m	Shared memory segments
	-q	Message queues
	-s	Semaphore arrays
	-a	All (default)
Output format:
	-t	Time
	-c	Creator
	-p	Pid
	-l	Limits
	-u	Summary
```

<a id="a-iplink"></a>

## `iplink`

```
Usage: iplink { set DEVICE { up | down | arp { on | off } | show [DEVICE] }

iplink set DEVICE { up | down | arp | multicast { on | off } |
			dynamic { on | off } |
			mtu MTU }
iplink show [DEVICE]
```

<a id="a-iproute"></a>

## `iproute`

```
Usage: iproute { list | flush | { add | del | change | append |
		replace | monitor } ROUTE }

iproute { list | flush } SELECTOR
iproute get ADDRESS [from ADDRESS iif STRING]
			[oif STRING] [tos TOS]
iproute { add | del | change | append | replace | monitor } ROUTE
			SELECTOR := [root PREFIX] [match PREFIX] [proto RTPROTO]
			ROUTE := [TYPE] PREFIX [tos TOS] [proto RTPROTO]
				[metric METRIC]
```

<a id="a-iprule"></a>

## `iprule`

```
Usage: iprule {[list | add | del] RULE}

iprule [list | add | del] SELECTOR ACTION
	SELECTOR := [from PREFIX] [to PREFIX] [tos TOS] [fwmark FWMARK]
			[dev STRING] [pref NUMBER]
	ACTION := [table TABLE_ID] [nat ADDRESS]
			[prohibit | reject | unreachable]
			[realms [SRCREALM/]DSTREALM]
	TABLE_ID := [local | main | default | NUMBER]
```

<a id="a-iptunnel"></a>

## `iptunnel`

```
Usage: iptunnel { add | change | del | show } [NAME]
	[mode { ipip | gre | sit }]
	[remote ADDR] [local ADDR] [ttl TTL]

iptunnel { add | change | del | show } [NAME]
	[mode { ipip | gre | sit }] [remote ADDR] [local ADDR]
	[[i|o]seq] [[i|o]key KEY] [[i|o]csum]
	[ttl TTL] [tos TOS] [[no]pmtudisc] [dev PHYS_DEV]
```

<a id="a-kbd_mode"></a>

## `kbd_mode`

```
Usage: kbd_mode [-a|k|s|u] [-C TTY]

Report or set the keyboard mode

	-a	Default (ASCII)
	-k	Medium-raw (keyboard)
	-s	Raw (scancode)
	-u	Unicode (utf-8)
	-C TTY	Affect TTY instead of /dev/tty
```

<a id="a-kill"></a>

## `kill`

```
Usage: kill [-l] [-SIG] PID...

Send a signal (default: TERM) to given PIDs

	-l	List all signal names and numbers
```

<a id="a-killall"></a>

## `killall`

```
Usage: killall [-l] [-q] [-SIG] PROCESS_NAME...

Send a signal (default: TERM) to given processes

	-l	List all signal names and numbers
	-q	Don't complain if no processes were killed
```

<a id="a-killall5"></a>

## `killall5`

```
Usage: killall5 [-l] [-SIG] [-o PID]...

Send a signal (default: TERM) to all processes outside current session

	-l	List all signal names and numbers
	-o PID	Don't signal this PID
```

<a id="a-klogd"></a>

## `klogd`

```
Usage: klogd [-c N] [-n]

Kernel logger

	-c N	Print to console messages more urgent than prio N (1-8)
	-n	Run in foreground
```

<a id="a-last"></a>

## `last`

```
Usage: last [-HW] [-f FILE]

Show listing of the last users that logged into the system

	-W	Display with no host column truncation
	-f FILE Read from FILE instead of /var/log/wtmp
```

<a id="a-less"></a>

## `less`

```
Usage: less [-EMNmh~I?] [FILE]...

View FILE (or stdin) one screenful at a time

	-E	Quit once the end of a file is reached
	-M,-m	Display status line with line numbers
		and percentage through the file
	-N	Prefix line number to each line
	-I	Ignore case in all searches
	-~	Suppress ~s displayed past the end of the file
```

<a id="a-linux32"></a>

## `linux32`

```
No help available.
```

<a id="a-linux64"></a>

## `linux64`

```
No help available.
```

<a id="a-ln"></a>

## `ln`

```
Usage: ln [OPTIONS] TARGET... LINK|DIR

Create a link LINK or DIR/TARGET to the specified TARGET(s)

	-s	Make symlinks instead of hardlinks
	-f	Remove existing destinations
	-n	Don't dereference symlinks - treat like normal file
	-b	Make a backup of the target (if exists) before link operation
	-S suf	Use suffix instead of ~ when making backup files
```

<a id="a-loadkmap"></a>

## `loadkmap`

```
Usage: loadkmap < keymap

Load a binary keyboard translation table from stdin
```

<a id="a-logger"></a>

## `logger`

```
Usage: logger [OPTIONS] [MESSAGE]

Write MESSAGE (or stdin) to syslog

	-s	Log to stderr as well as the system log
	-t TAG	Log using the specified tag (defaults to user name)
	-p PRIO	Priority (numeric or facility.level pair)
```

<a id="a-login"></a>

## `login`

```
Usage: login [-p] [-h HOST] [[-f] USER]

Begin a new session on the system

	-f	Don't authenticate (user already authenticated)
	-h	Name of the remote host
	-p	Preserve environment
```

<a id="a-logname"></a>

## `logname`

```
Usage: logname 

Print the name of the current user
```

<a id="a-logread"></a>

## `logread`

```
Usage: logread [-f]

Show messages in syslogd's circular buffer

	-f	Output data as log grows
```

<a id="a-losetup"></a>

## `losetup`

```
Usage: losetup [-o OFS] LOOPDEV FILE - associate loop devices
	losetup -d LOOPDEV - disassociate
	losetup [-f] - show

	-o OFS	Start OFS bytes into FILE
	-f	Show first free loop device
```

<a id="a-ls"></a>

## `ls`

```
Usage: ls [-1AaCxdLHRFplinsehrSXvctu] [-w WIDTH] [FILE]...

List directory contents

	-1	One column output
	-a	Include entries which start with .
	-A	Like -a, but exclude . and ..
	-C	List by columns
	-x	List by lines
	-d	List directory entries instead of contents
	-L	Follow symlinks
	-H	Follow symlinks on command line
	-R	Recurse
	-p	Append / to dir entries
	-F	Append indicator (one of */=@|) to entries
	-l	Long listing format
	-i	List inode numbers
	-n	List numeric UIDs and GIDs instead of names
	-s	List allocated blocks
	-e	List full date and time
	-h	List sizes in human readable format (1K 243M 2G)
	-r	Sort in reverse order
	-S	Sort by size
	-X	Sort by extension
	-v	Sort by version
	-c	With -l: sort by ctime
	-t	With -l: sort by mtime
	-u	With -l: sort by atime
	-w N	Assume the terminal is N columns wide
	--color[={always,never,auto}]	Control coloring
```

<a id="a-lsattr"></a>

## `lsattr`

```
Usage: lsattr [-Radlv] [FILE]...

List file attributes on an ext2 fs

	-R	Recurse
	-a	Don't hide entries starting with .
	-d	List directory entries instead of contents
	-l	List long flag names
	-v	List the file's version/generation number
```

<a id="a-lsmod"></a>

## `lsmod`

```
Usage: lsmod [-qfwrsv] MODULE [symbol=value]...

	-r	Remove MODULE (stacks) or do autoclean
	-q	Quiet
	-v	Verbose
	-f	Force
	-w	Wait for unload
	-s	Report via syslog instead of stderr
```

<a id="a-lspci"></a>

## `lspci`

```
Usage: lspci [-mk]

List all PCI devices

	-m	Parsable output
	-k	Show driver
```

<a id="a-lsusb"></a>

## `lsusb`

```
No help available.
```

<a id="a-lzop"></a>

## `lzop`

```
Usage: lzop [-cfvd123456789CF] [FILE]...

	-1..9	Compression level
	-d	Decompress
	-c	Write to stdout
	-f	Force
	-v	Verbose
	-F	Don't store or verify checksum
	-C	Also write checksum of compressed block
```

<a id="a-lzopcat"></a>

## `lzopcat`

```
Usage: lzopcat [-vCF] [FILE]...

	-v	Verbose
	-F	Don't store or verify checksum
```

<a id="a-makedevs"></a>

## `makedevs`

```
Usage: makedevs [-d device_table] rootdir

Create a range of special files as specified in a device table.
Device table entries take the form of:
<name> <type> <mode> <uid> <gid> <major> <minor> <start> <inc> <count>
Where name is the file name, type can be one of:
	f	Regular file
	d	Directory
	c	Character device
	b	Block device
	p	Fifo (named pipe)
uid is the user id for the target file, gid is the group id for the
target file. The rest of the entries (major, minor, etc) apply to
to device special files. A '-' may be used for blank entries.
```

<a id="a-md5sum"></a>

## `md5sum`

```
Usage: md5sum [-c[sw]] [FILE]...

Print or check MD5 checksums

	-c	Check sums against list in FILEs
	-s	Don't output anything, status code shows success
	-w	Warn about improperly formatted checksum lines
```

<a id="a-mdev"></a>

## `mdev`

```
Usage: mdev [-s]

	-s	Scan /sys and populate /dev during system boot

It can be run by kernel as a hotplug helper. To activate it:
 echo /sbin/mdev > /proc/sys/kernel/hotplug
It uses /etc/mdev.conf with lines
[-]DEVNAME UID:GID PERM [>|=PATH] [@|$|*PROG]
```

<a id="a-mkdir"></a>

## `mkdir`

```
Usage: mkdir [OPTIONS] DIRECTORY...

Create DIRECTORY

	-m MODE	Mode
	-p	No error if exists; make parent directories as needed
```

<a id="a-mke2fs"></a>

## `mke2fs`

```
Usage: mke2fs [-Fn] [-b BLK_SIZE] [-i INODE_RATIO] [-I INODE_SIZE] [-m RESERVED_PERCENT] [-L LABEL] BLOCKDEV [KBYTES]

	-b BLK_SIZE	Block size, bytes
	-F		Force
	-i RATIO	Max number of files is filesystem_size / RATIO
	-I BYTES	Inode size (min 128)
	-L LBL		Volume label
	-m PERCENT	Percent of blocks to reserve for admin
	-n		Dry run
```

<a id="a-mkfifo"></a>

## `mkfifo`

```
Usage: mkfifo [-m MODE] NAME

Create named pipe

	-m MODE	Mode (default a=rw)
```

<a id="a-mkfs_ext2"></a>

## `mkfs.ext2`

```
Usage: mkfs.ext2 [-Fn] [-b BLK_SIZE] [-i INODE_RATIO] [-I INODE_SIZE] [-m RESERVED_PERCENT] [-L LABEL] BLOCKDEV [KBYTES]

	-b BLK_SIZE	Block size, bytes
	-F		Force
	-i RATIO	Max number of files is filesystem_size / RATIO
	-I BYTES	Inode size (min 128)
	-L LBL		Volume label
	-m PERCENT	Percent of blocks to reserve for admin
	-n		Dry run
```

<a id="a-mknod"></a>

## `mknod`

```
Usage: mknod [-m MODE] NAME TYPE MAJOR MINOR

Create a special file (block, character, or pipe)

	-m MODE	Creation mode (default a=rw)
TYPE:
	b	Block device
	c or u	Character device
	p	Named pipe (MAJOR and MINOR are ignored)
```

<a id="a-mkpasswd"></a>

## `mkpasswd`

```
Usage: mkpasswd [OPTIONS] [PASSWORD] [SALT]

Crypt PASSWORD using crypt(3)

	-P,--password-fd=N	Read password from fd N
	-m,--method=TYPE	Encryption method
	-S,--salt=SALT
```

<a id="a-mkswap"></a>

## `mkswap`

```
Usage: mkswap [-L LBL] BLOCKDEV [KBYTES]

Prepare BLOCKDEV to be used as swap partition

	-L LBL	Label
```

<a id="a-mktemp"></a>

## `mktemp`

```
Usage: mktemp [-dt] [-p DIR] [TEMPLATE]

Create a temporary file with name based on TEMPLATE and print its name.
TEMPLATE must end with XXXXXX (e.g. [/dir/]nameXXXXXX).
Without TEMPLATE, -t tmp.XXXXXX is assumed.

	-d	Make directory, not file
	-t	Prepend base directory name to TEMPLATE
	-p DIR	Use DIR as a base directory (implies -t)

Base directory is: -p DIR, else $TMPDIR, else /tmp
```

<a id="a-modinfo"></a>

## `modinfo`

```
Usage: modinfo [-adlp0] [-F keyword] MODULE

	-a		Shortcut for '-F author'
	-d		Shortcut for '-F description'
	-l		Shortcut for '-F license'
	-p		Shortcut for '-F parm'
	-F keyword	Keyword to look for
	-0		Separate output with NULs
```

<a id="a-modprobe"></a>

## `modprobe`

```
Usage: modprobe [-qfwrsv] MODULE [symbol=value]...

	-r	Remove MODULE (stacks) or do autoclean
	-q	Quiet
	-v	Verbose
	-f	Force
	-w	Wait for unload
	-s	Report via syslog instead of stderr
```

<a id="a-more"></a>

## `more`

```
Usage: more [FILE]...

View FILE (or stdin) one screenful at a time
```

<a id="a-mount"></a>

## `mount`

```
Usage: mount [OPTIONS] [-o OPTS] DEVICE NODE

Mount a filesystem. Filesystem autodetection requires /proc.

	-a		Mount all filesystems in fstab
	-f		Dry run
	-r		Read-only mount
	-w		Read-write mount (default)
	-t FSTYPE	Filesystem type
	-O OPT		Mount only filesystems with option OPT (-a only)
-o OPT:
	loop		Ignored (loop devices are autodetected)
	[a]sync		Writes are [a]synchronous
	[no]atime	Disable/enable updates to inode access times
	[no]diratime	Disable/enable atime updates to directories
	[no]relatime	Disable/enable atime updates relative to modification time
	[no]dev		(Dis)allow use of special device files
	[no]exec	(Dis)allow use of executable files
	[no]suid	(Dis)allow set-user-id-root programs
	[r]shared	Convert [recursively] to a shared subtree
	[r]slave	Convert [recursively] to a slave subtree
	[r]private	Convert [recursively] to a private subtree
	[un]bindable	Make mount point [un]able to be bind mounted
	[r]bind		Bind a file or directory [recursively] to another location
	move		Relocate an existing mount point
	remount		Remount a mounted filesystem, changing flags
	ro/rw		Same as -r/-w

There are filesystem-specific -o flags.
```

<a id="a-mountpoint"></a>

## `mountpoint`

```
Usage: mountpoint [-q] <[-dn] DIR | -x DEVICE>

Check if the directory is a mountpoint

	-q	Quiet
	-d	Print major/minor device number of the filesystem
	-n	Print device name of the filesystem
	-x	Print major/minor device number of the blockdevice
```

<a id="a-mpstat"></a>

## `mpstat`

```
Usage: mpstat [-A] [-I SUM|CPU|ALL|SCPU] [-u] [-P num|ALL] [INTERVAL [COUNT]]

Per-processor statistics

	-A			Same as -I ALL -u -P ALL
	-I SUM|CPU|ALL|SCPU	Report interrupt statistics
	-P num|ALL		Processor to monitor
	-u			Report CPU utilization
```

<a id="a-mv"></a>

## `mv`

```
Usage: mv [-fin] SOURCE DEST
or: mv [-fin] SOURCE... DIRECTORY

Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY

	-f	Don't prompt before overwriting
	-i	Interactive, prompt before overwrite
	-n	Don't overwrite an existing file
```

<a id="a-nameif"></a>

## `nameif`

```
Usage: nameif [-s] [-c FILE] [IFNAME SELECTOR]...

Rename network interface while it in the down state.
The device matched by SELECTOR is renamed to IFACE.
SELECTOR can be a combination of:
	driver=STRING
	bus=STRING
	phy_address=NUM
	[mac=]XX:XX:XX:XX:XX:XX

	-c FILE	Configuration file (default: /etc/mactab)
	-s	Log to syslog
```

<a id="a-nbd_client"></a>

## `nbd-client`

```
Usage: nbd-client HOST PORT BLOCKDEV

Connect to HOST and provide a network block device on BLOCKDEV
```

<a id="a-nc"></a>

## `nc`

```
Usage: nc [-iN] [-wN] [-f FILE|IPADDR PORT] [-e PROG]

Open a pipe to IP:PORT or FILE

	-e PROG	Run PROG after connect
	-w SEC	Timeout for connect
	-i SEC	Delay interval for lines sent
	-f FILE	Use file (ala /dev/ttyS0) instead of network
```

<a id="a-netstat"></a>

## `netstat`

```
Usage: netstat [-ral] [-tuwx] [-enWp]

Display networking information

	-r	Routing table
	-a	All sockets
	-l	Listening sockets
		Else: connected sockets
	-t	TCP sockets
	-u	UDP sockets
	-w	Raw sockets
	-x	Unix sockets
		Else: all socket types
	-e	Other/more information
	-n	Don't resolve names
	-W	Wide display
	-p	Show PID/program name for sockets
```

<a id="a-nice"></a>

## `nice`

```
Usage: nice [-n ADJUST] [PROG ARGS]

Change scheduling priority, run PROG

	-n ADJUST	Adjust priority by ADJUST
```

<a id="a-nmeter"></a>

## `nmeter`

```
Usage: nmeter [-d MSEC] FORMAT_STRING

Monitor system in real time

 -d MSEC	Milliseconds between updates (default:1000)

Format specifiers:
 %Nc or %[cN]	CPU. N - bar size (default:10)
		(displays: S:system U:user N:niced D:iowait I:irq i:softirq)
 %[nINTERFACE]	Network INTERFACE
 %m		Allocated memory
 %[mf]		Free memory
 %[mt]		Total memory
 %s		Allocated swap
 %f		Number of used file descriptors
 %Ni		Total/specific IRQ rate
 %x		Context switch rate
 %p		Forks
 %[pn]		# of processes
 %b		Block io
 %Nt		Time (with N decimal points)
 %r		Print <cr> instead of <lf> at EOL
```

<a id="a-nohup"></a>

## `nohup`

```
Usage: nohup PROG ARGS

Run PROG immune to hangups, with output to a non-tty
```

<a id="a-nslookup"></a>

## `nslookup`

```
Usage: nslookup [HOST] [SERVER]

Query the nameserver for the IP address of the given HOST
optionally using a specified DNS server
```

<a id="a-ntpd"></a>

## `ntpd`

```
Usage: ntpd [-dnqNwl] [-S PROG] [-p PEER]...

NTP client/server

	-d	Verbose
	-n	Do not daemonize
	-q	Quit after clock is set
	-N	Run at high priority
	-w	Do not set time (only query peers), implies -n
	-l	Run as server on port 123
	-S PROG	Run PROG after stepping time, stratum change, and every 11 mins
	-p PEER	Obtain time from PEER (may be repeated)
```

<a id="a-od"></a>

## `od`

```
Usage: od [-abcdfhilovxs] [-t TYPE] [-A RADIX] [-N SIZE] [-j SKIP] [-S MINSTR] [-w WIDTH] [FILE...]

Print FILEs (or stdin) unambiguously, as octal bytes by default
```

<a id="a-openvt"></a>

## `openvt`

```
Usage: openvt [-c N] [-sw] [PROG ARGS]

Start PROG on a new virtual terminal

	-c N	Use specified VT
	-s	Switch to the VT
	-w	Wait for PROG to exit
```

<a id="a-passwd"></a>

## `passwd`

```
Usage: passwd [OPTIONS] [USER]

Change USER's password (default: current user)

	-a ALG	Encryption method
	-d	Set password to ''
	-l	Lock (disable) account
	-u	Unlock (enable) account
```

<a id="a-patch"></a>

## `patch`

```
Usage: patch [OPTIONS] [ORIGFILE [PATCHFILE]]

	-p,--strip N		Strip N leading components from file names
	-i,--input DIFF		Read DIFF instead of stdin
	-R,--reverse		Reverse patch
	-N,--forward		Ignore already applied patches
	-E,--remove-empty-files	Remove output files if they become empty
```

<a id="a-pgrep"></a>

## `pgrep`

```
Usage: pgrep [-flnovx] [-s SID|-P PPID|PATTERN]

Display process(es) selected by regex PATTERN

	-l	Show command name too
	-f	Match against entire command line
	-n	Show the newest process only
	-o	Show the oldest process only
	-v	Negate the match
	-x	Match whole name (not substring)
	-s	Match session ID (0 for current)
	-P	Match parent process ID
```

<a id="a-pidof"></a>

## `pidof`

```
Usage: pidof [OPTIONS] [NAME]...

List PIDs of all processes with names that match NAMEs

	-s	Show only one PID
	-o PID	Omit given pid
		Use %PPID to omit pid of pidof's parent
```

<a id="a-ping"></a>

## `ping`

```
Usage: ping [OPTIONS] HOST

Send ICMP ECHO_REQUEST packets to network hosts

	-4,-6		Force IP or IPv6 name resolution
	-c CNT		Send only CNT pings
	-s SIZE		Send SIZE data bytes in packets (default:56)
	-t TTL		Set TTL
	-I IFACE/IP	Use interface or IP address as source
	-W SEC		Seconds to wait for the first response (default:10)
			(after all -c CNT packets are sent)
	-w SEC		Seconds until ping exits (default:infinite)
			(can exit earlier with -c CNT)
	-q		Quiet, only displays output at start
			and when finished
```

<a id="a-pipe_progress"></a>

## `pipe_progress`

```
No help available.
```

<a id="a-pkill"></a>

## `pkill`

```
Usage: pkill [-l|-SIGNAL] [-fnovx] [-s SID|-P PPID|PATTERN]

Send a signal to process(es) selected by regex PATTERN

	-l	List all signals
	-f	Match against entire command line
	-n	Signal the newest process only
	-o	Signal the oldest process only
	-v	Negate the match
	-x	Match whole name (not substring)
	-s	Match session ID (0 for current)
	-P	Match parent process ID
```

<a id="a-pmap"></a>

## `pmap`

```
Usage: pmap [-xq] PID

Display detailed process memory usage

	-x	Show details
	-q	Quiet
```

<a id="a-poweroff"></a>

## `poweroff`

```
Usage: poweroff [-d DELAY] [-n] [-f]

Halt and shut off power

	-d SEC	Delay interval
	-n	Do not sync
	-f	Force (don't go through init)
```

<a id="a-powertop"></a>

## `powertop`

```
Usage: powertop 

Analyze power consumption on Intel-based laptops
```

<a id="a-printenv"></a>

## `printenv`

```
Usage: printenv [VARIABLE]...

Print environment VARIABLEs.
If no VARIABLE specified, print all.
```

<a id="a-printf"></a>

## `printf`

```
Usage: printf FORMAT [ARGUMENT]...

Format and print ARGUMENT(s) according to FORMAT,
where FORMAT controls the output exactly as in C printf
```

<a id="a-ps"></a>

## `ps`

```
Usage: ps [-o COL1,COL2=HEADER] [-T]

Show list of processes

	-o COL1,COL2=HEADER	Select columns for display
	-T			Show threads
```

<a id="a-pscan"></a>

## `pscan`

```
Usage: pscan [-cb] [-p MIN_PORT] [-P MAX_PORT] [-t TIMEOUT] [-T MIN_RTT] HOST

Scan a host, print all open ports

	-c	Show closed ports too
	-b	Show blocked ports too
	-p	Scan from this port (default 1)
	-P	Scan up to this port (default 1024)
	-t	Timeout (default 5000 ms)
	-T	Minimum rtt (default 5 ms, increase for congested hosts)
```

<a id="a-pstree"></a>

## `pstree`

```
Usage: pstree [-p] [PID|USER]

Display process tree, optionally start from USER or PID

	-p	Show pids
```

<a id="a-pwd"></a>

## `pwd`

```
Usage: pwd 

Print the full filename of the current working directory
```

<a id="a-pwdx"></a>

## `pwdx`

```
Usage: pwdx PID...

Show current directory for PIDs
```

<a id="a-rdate"></a>

## `rdate`

```
Usage: rdate [-sp] HOST

Get and possibly set the system date and time from a remote HOST

	-s	Set the system date and time (default)
	-p	Print the date and time
```

<a id="a-rdev"></a>

## `rdev`

```
Usage: rdev 

Print the device node associated with the filesystem mounted at '/'
```

<a id="a-readlink"></a>

## `readlink`

```
Usage: readlink [-fnv] FILE

Display the value of a symlink

	-f	Canonicalize by following all symlinks
	-n	Don't add newline
	-v	Verbose
```

<a id="a-readprofile"></a>

## `readprofile`

```
Usage: readprofile [OPTIONS]

	-m mapfile	(Default: /boot/System.map)
	-p profile	(Default: /proc/profile)
	-M NUM		Set the profiling multiplier to NUM
	-i		Print only info about the sampling step
	-v		Verbose
	-a		Print all symbols, even if count is 0
	-b		Print individual histogram-bin counts
	-s		Print individual counters within functions
	-r		Reset all the counters (root only)
	-n		Disable byte order auto-detection
```

<a id="a-realpath"></a>

## `realpath`

```
Usage: realpath FILE...

Return the absolute pathnames of given FILE
```

<a id="a-reboot"></a>

## `reboot`

```
Usage: reboot [-d DELAY] [-n] [-f]

Reboot the system

	-d SEC	Delay interval
	-n	Do not sync
	-f	Force (don't go through init)
```

<a id="a-remove_shell"></a>

## `remove-shell`

```
Usage: remove-shell SHELL...

Remove SHELLs from /etc/shells
```

<a id="a-renice"></a>

## `renice`

```
Usage: renice {{-n INCREMENT} | PRIORITY} [[-p | -g | -u] ID...]

Change scheduling priority for a running process

	-n	Adjust current nice value (smaller is faster)
	-p	Process id(s) (default)
	-g	Process group id(s)
	-u	Process user name(s) and/or id(s)
```

<a id="a-reset"></a>

## `reset`

```
Usage: reset 

Reset the screen
```

<a id="a-resize"></a>

## `resize`

```
Usage: resize 

Resize the screen
```

<a id="a-rev"></a>

## `rev`

```
Usage: rev [FILE]...

Reverse lines of FILE
```

<a id="a-rm"></a>

## `rm`

```
Usage: rm [-irf] FILE...

Remove (unlink) FILEs

	-i	Always prompt before removing
	-f	Never prompt
	-R,-r	Recurse
```

<a id="a-rmdir"></a>

## `rmdir`

```
Usage: rmdir [OPTIONS] DIRECTORY...

Remove DIRECTORY if it is empty

	-p|--parents	Include parents
	--ignore-fail-on-non-empty
```

<a id="a-rmmod"></a>

## `rmmod`

```
Usage: rmmod [-qfwrsv] MODULE [symbol=value]...

	-r	Remove MODULE (stacks) or do autoclean
	-q	Quiet
	-v	Verbose
	-f	Force
	-w	Wait for unload
	-s	Report via syslog instead of stderr
```

<a id="a-route"></a>

## `route`

```
Usage: route [{add|del|delete}]

Edit kernel routing tables

	-n	Don't resolve names
	-e	Display other/more information
	-A inet{6}	Select address family
```

<a id="a-rpm"></a>

## `rpm`

```
Usage: rpm -i PACKAGE.rpm; rpm -qp[ildc] PACKAGE.rpm

Manipulate RPM packages

Commands:
	-i	Install package
	-qp	Query package
	-i	Show information
	-l	List contents
	-d	List documents
	-c	List config files
```

<a id="a-rpm2cpio"></a>

## `rpm2cpio`

```
Usage: rpm2cpio package.rpm

Output a cpio archive of the rpm file
```

<a id="a-rtcwake"></a>

## `rtcwake`

```
Usage: rtcwake [-a | -l | -u] [-d DEV] [-m MODE] [-s SEC | -t TIME]

Enter a system sleep state until specified wakeup time

	-a,--auto	Read clock mode from adjtime
	-l,--local	Clock is set to local time
	-u,--utc	Clock is set to UTC time
	-d,--device=DEV	Specify the RTC device
	-m,--mode=MODE	Set the sleep state (default: standby)
	-s,--seconds=SEC Set the timeout in SEC seconds from now
	-t,--time=TIME	Set the timeout to TIME seconds from epoch
```

<a id="a-run_parts"></a>

## `run-parts`

```
Usage: run-parts [-t] [-l] [-a ARG] [-u MASK] DIRECTORY

Run a bunch of scripts in DIRECTORY

	-t	Print what would be run, but don't actually run anything
	-a ARG	Pass ARG as argument for every program
	-u MASK	Set the umask to MASK before running every program
	-l	Print names of all matching files even if they are not executable
```

<a id="a-rx"></a>

## `rx`

```
Usage: rx FILE

Receive a file using the xmodem protocol
```

<a id="a-script"></a>

## `script`

```
Usage: script [-afqt] [-c PROG] [OUTFILE]

	-a	Append output
	-c PROG	Run PROG, not shell
	-f	Flush output after each write
	-q	Quiet
	-t	Send timing to stderr
```

<a id="a-scriptreplay"></a>

## `scriptreplay`

```
Usage: scriptreplay timingfile [typescript [divisor]]

Play back typescripts, using timing information
```

<a id="a-sed"></a>

## `sed`

```
Usage: sed [-efinr] SED_CMD [FILE]...

	-e CMD	Add CMD to sed commands to be executed
	-f FILE	Add FILE contents to sed commands to be executed
	-i	Edit files in-place (else sends result to stdout)
	-n	Suppress automatic printing of pattern space
	-r	Use extended regex syntax

If no -e or -f, the first non-option argument is the sed command string.
Remaining arguments are input files (stdin if none).
```

<a id="a-seq"></a>

## `seq`

```
Usage: seq [-w] [-s SEP] [FIRST [INC]] LAST

Print numbers from FIRST to LAST, in steps of INC.
FIRST, INC default to 1.

	-w	Pad to last with leading zeros
	-s SEP	String separator
```

<a id="a-setarch"></a>

## `setarch`

```
Usage: setarch personality PROG ARGS

Personality may be:
	linux32		Set 32bit uname emulation
	linux64		Set 64bit uname emulation
```

<a id="a-setconsole"></a>

## `setconsole`

```
Usage: setconsole [-r|--reset] [DEVICE]

Redirect system console output to DEVICE (default: /dev/tty)

	-r	Reset output to /dev/console
```

<a id="a-setfont"></a>

## `setfont`

```
Usage: setfont FONT [-m MAPFILE] [-C TTY]

Load a console font

	-m MAPFILE	Load console screen map
	-C TTY		Affect TTY instead of /dev/tty
```

<a id="a-setkeycodes"></a>

## `setkeycodes`

```
Usage: setkeycodes SCANCODE KEYCODE...

Set entries into the kernel's scancode-to-keycode map,
allowing unusual keyboards to generate usable keycodes.

SCANCODE may be either xx or e0xx (hexadecimal),
and KEYCODE is given in decimal.
```

<a id="a-setlogcons"></a>

## `setlogcons`

```
Usage: setlogcons N

Redirect the kernel output to console N (0 for current)
```

<a id="a-setsid"></a>

## `setsid`

```
Usage: setsid PROG ARGS

Run PROG in a new session. PROG will have no controlling terminal
and will not be affected by keyboard signals (Ctrl-C etc).
See setsid(2) for details.
```

<a id="a-sh"></a>

## `sh`

```
Usage: sh [-/+OPTIONS] [-/+o OPT]... [-c 'SCRIPT' [ARG0 [ARGS]] / FILE [ARGS]]

Unix shell interpreter
```

<a id="a-showkey"></a>

## `showkey`

```
Usage: showkey [-a | -k | -s]

Show keys pressed

	-a	Display decimal/octal/hex values of the keys
	-k	Display interpreted keycodes (default)
	-s	Display raw scan-codes
```

<a id="a-slattach"></a>

## `slattach`

```
Usage: slattach [-cehmLF] [-s SPEED] [-p PROTOCOL] DEVICE

Attach network interface(s) to serial line(s)

	-p PROT	Set protocol (slip, cslip, slip6, clisp6 or adaptive)
	-s SPD	Set line speed
	-e	Exit after initializing device
	-h	Exit when the carrier is lost
	-c PROG	Run PROG when the line is hung up
	-m	Do NOT initialize the line in raw 8 bits mode
	-L	Enable 3-wire operation
	-F	Disable RTS/CTS flow control
```

<a id="a-sleep"></a>

## `sleep`

```
Usage: sleep [N]...

Pause for a time equal to the total of the args given, where each arg can
have an optional suffix of (s)econds, (m)inutes, (h)ours, or (d)ays
```

<a id="a-smemcap"></a>

## `smemcap`

```
Usage: smemcap >SMEMDATA.TAR

Collect memory usage data in /proc and write it to stdout
```

<a id="a-sort"></a>

## `sort`

```
Usage: sort [-nrugMcszbdfimSTokt] [-o FILE] [-k start[.offset][opts][,end[.offset][opts]] [-t CHAR] [FILE]...

Sort lines of text

	-b	Ignore leading blanks
	-c	Check whether input is sorted
	-d	Dictionary order (blank or alphanumeric only)
	-f	Ignore case
	-g	General numerical sort
	-i	Ignore unprintable characters
	-k	Sort key
	-M	Sort month
	-n	Sort numbers
	-o	Output to file
	-k	Sort by key
	-t CHAR	Key separator
	-r	Reverse sort order
	-s	Stable (don't sort ties alphabetically)
	-u	Suppress duplicate lines
	-z	Lines are terminated by NUL, not newline
	-mST	Ignored for GNU compatibility
```

<a id="a-split"></a>

## `split`

```
Usage: split [OPTIONS] [INPUT [PREFIX]]

	-b N[k|m]	Split by N (kilo|mega)bytes
	-l N		Split by N lines
	-a N		Use N letters as suffix
```

<a id="a-stat"></a>

## `stat`

```
Usage: stat [OPTIONS] FILE...

Display file (default) or filesystem status

	-c fmt	Use the specified format
	-f	Display filesystem status
	-L	Follow links
	-t	Display info in terse form

Valid format sequences for files:
 %a	Access rights in octal
 %A	Access rights in human readable form
 %b	Number of blocks allocated (see %B)
 %B	The size in bytes of each block reported by %b
 %d	Device number in decimal
 %D	Device number in hex
 %f	Raw mode in hex
 %F	File type
 %g	Group ID of owner
 %G	Group name of owner
 %h	Number of hard links
 %i	Inode number
 %n	File name
 %N	File name, with -> TARGET if symlink
 %o	I/O block size
 %s	Total size, in bytes
 %t	Major device type in hex
 %T	Minor device type in hex
 %u	User ID of owner
 %U	User name of owner
 %x	Time of last access
 %X	Time of last access as seconds since Epoch
 %y	Time of last modification
 %Y	Time of last modification as seconds since Epoch
 %z	Time of last change
 %Z	Time of last change as seconds since Epoch

Valid format sequences for file systems:
 %a	Free blocks available to non-superuser
 %b	Total data blocks in file system
 %c	Total file nodes in file system
 %d	Free file nodes in file system
 %f	Free blocks in file system
 %i	File System ID in hex
 %l	Maximum length of filenames
 %n	File name
 %s	Block size (for faster transfer)
 %S	Fundamental block size (for block counts)
 %t	Type in hex
 %T	Type in human readable form
```

<a id="a-strings"></a>

## `strings`

```
Usage: strings [-afo] [-n LEN] [FILE]...

Display printable strings in a binary file

	-a	Scan whole file (default)
	-f	Precede strings with filenames
	-n LEN	At least LEN characters form a string (default 4)
	-o	Precede strings with decimal offsets
```

<a id="a-stty"></a>

## `stty`

```
Usage: stty [-a|g] [-F DEVICE] [SETTING]...

Without arguments, prints baud rate, line discipline,
and deviations from stty sane

	-F DEVICE	Open device instead of stdin
	-a		Print all current settings in human-readable form
	-g		Print in stty-readable form
	[SETTING]	See manpage
```

<a id="a-su"></a>

## `su`

```
Usage: su [OPTIONS] [-] [USER]

Run shell under USER (by default, root)

	-,-l	Clear environment, run shell as login shell
	-p,-m	Do not set new $HOME, $SHELL, $USER, $LOGNAME
	-c CMD	Command to pass to 'sh -c'
	-s SH	Shell to use instead of user's default
```

<a id="a-sulogin"></a>

## `sulogin`

```
Usage: sulogin [-t N] [TTY]

Single user login

	-t N	Timeout
```

<a id="a-sum"></a>

## `sum`

```
Usage: sum [-rs] [FILE]...

Checksum and count the blocks in a file

	-r	Use BSD sum algorithm (1K blocks)
	-s	Use System V sum algorithm (512byte blocks)
```

<a id="a-swapoff"></a>

## `swapoff`

```
Usage: swapoff [-a] [DEVICE]

Stop swapping on DEVICE

	-a	Stop swapping on all swap devices
```

<a id="a-swapon"></a>

## `swapon`

```
Usage: swapon [-a] [-p PRI] [DEVICE]

Start swapping on DEVICE

	-a	Start swapping on all swap devices
	-p PRI	Set swap device priority
```

<a id="a-sync"></a>

## `sync`

```
Usage: sync 

Write all buffered blocks to disk
```

<a id="a-sysctl"></a>

## `sysctl`

```
Usage: sysctl [OPTIONS] [VALUE]...

Configure kernel parameters at runtime

	-n	Don't print key names
	-e	Don't warn about unknown keys
	-w	Change sysctl setting
	-p FILE	Load sysctl settings from FILE (default /etc/sysctl.conf)
	-a	Display all values
	-A	Display all values in table form
```

<a id="a-syslogd"></a>

## `syslogd`

```
Usage: syslogd [OPTIONS]

System logging utility

	-n		Run in foreground
	-O FILE		Log to FILE (default:/var/log/messages)
	-l N		Log only messages more urgent than prio N (1-8)
	-S		Smaller output
	-s SIZE		Max size (KB) before rotation (default:200KB, 0=off)
	-b N		N rotated logs to keep (default:1, max=99, 0=purge)
	-R HOST[:PORT]	Log to IP or hostname on PORT (default PORT=514/UDP)
	-L		Log locally and via network (default is network only if -R)
	-D		Drop duplicates
	-C[size_kb]	Log to shared mem buffer (use logread to read it)
	-f FILE		Use FILE as config (default:/etc/syslog.conf)
```

<a id="a-tac"></a>

## `tac`

```
Usage: tac [FILE]...

Concatenate FILEs and print them in reverse
```

<a id="a-tail"></a>

## `tail`

```
Usage: tail [OPTIONS] [FILE]...

Print last 10 lines of each FILE (or stdin) to stdout.
With more than one FILE, precede each with a filename header.

	-f		Print data as file grows
	-s SECONDS	Wait SECONDS between reads with -f
	-n N[kbm]	Print last N lines
	-c N[kbm]	Print last N bytes
	-q		Never print headers
	-v		Always print headers

N may be suffixed by k (x1024), b (x512), or m (x1024^2).
If N starts with a '+', output begins with the Nth item from the start
of each file, not from the end.
```

<a id="a-tar"></a>

## `tar`

```
Usage: tar -[cxtzjhmvO] [-X FILE] [-T FILE] [-f TARFILE] [-C DIR] [FILE]...

Create, extract, or list files from a tar file

Operation:
	c	Create
	x	Extract
	t	List
	f	Name of TARFILE ('-' for stdin/out)
	C	Change to DIR before operation
	v	Verbose
	z	(De)compress using gzip
	j	(De)compress using bzip2
	O	Extract to stdout
	h	Follow symlinks
	m	Don't restore mtime
	exclude	File to exclude
	X	File with names to exclude
	T	File with names to include
```

<a id="a-taskset"></a>

## `taskset`

```
Usage: taskset [-p] [MASK] [PID | PROG ARGS]

Set or get CPU affinity

	-p	Operate on an existing PID
```

<a id="a-tcpsvd"></a>

## `tcpsvd`

```
Usage: tcpsvd [-hEv] [-c N] [-C N[:MSG]] [-b N] [-u USER] [-l NAME] IP PORT PROG

Create TCP socket, bind to IP:PORT and listen
for incoming connection. Run PROG for each connection.

	IP		IP to listen on, 0 = all
	PORT		Port to listen on
	PROG ARGS	Program to run
	-l NAME		Local hostname (else looks up local hostname in DNS)
	-u USER[:GRP]	Change to user/group after bind
	-c N		Handle up to N connections simultaneously
	-b N		Allow a backlog of approximately N TCP SYNs
	-C N[:MSG]	Allow only up to N connections from the same IP
			New connections from this IP address are closed
			immediately. MSG is written to the peer before close
	-h		Look up peer's hostname
	-E		Don't set up environment variables
	-v		Verbose
```

<a id="a-tee"></a>

## `tee`

```
Usage: tee [-ai] [FILE]...

Copy stdin to each FILE, and also to stdout

	-a	Append to the given FILEs, don't overwrite
	-i	Ignore interrupt signals (SIGINT)
```

<a id="a-test"></a>

## `test`

```
(no output)
```

<a id="a-time"></a>

## `time`

```
Usage: time [-v] PROG ARGS

Run PROG, display resource usage when it exits

	-v	Verbose
```

<a id="a-timeout"></a>

## `timeout`

```
Usage: timeout [-t SECS] [-s SIG] PROG ARGS

Runs PROG. Sends SIG to it if it is not gone in SECS seconds.
Defaults: SECS: 10, SIG: TERM.
```

<a id="a-top"></a>

## `top`

```
Usage: top [-b] [-nCOUNT] [-dSECONDS] [-m]

Provide a view of process activity in real time.
Read the status of all processes from /proc each SECONDS
and display a screenful of them.
Keys:
	N/M/P/T: show CPU usage, sort by pid/mem/cpu/time
	S: show memory
	R: reverse sort
	H: toggle threads, 1: toggle SMP
	Q,^C: exit

Options:
	-b	Batch mode
	-n N	Exit after N iterations
	-d N	Delay between updates
	-m	Same as 's' key
```

<a id="a-touch"></a>

## `touch`

```
Usage: touch [-c] [-d DATE] [-r FILE] FILE [FILE]...

Update the last-modified date on the given FILE[s]

	-c	Don't create files
	-d DT	Date/time to use
	-r FILE	Use FILE's date/time
```

<a id="a-tr"></a>

## `tr`

```
Usage: tr [-cds] STRING1 [STRING2]

Translate, squeeze, or delete characters from stdin, writing to stdout

	-c	Take complement of STRING1
	-d	Delete input characters coded STRING1
	-s	Squeeze multiple output characters of STRING2 into one character
```

<a id="a-traceroute"></a>

## `traceroute`

```
Usage: traceroute [-FIldnrv] [-f 1ST_TTL] [-m MAXTTL] [-p PORT] [-q PROBES]
	[-s SRC_IP] [-t TOS] [-w WAIT_SEC] [-g GATEWAY] [-i IFACE]
	[-z PAUSE_MSEC] HOST [BYTES]

Trace the route to HOST

	-F	Set the don't fragment bit
	-I	Use ICMP ECHO instead of UDP datagrams
	-l	Display the TTL value of the returned packet
	-d	Set SO_DEBUG options to socket
	-n	Print numeric addresses
	-r	Bypass routing tables, send directly to HOST
	-v	Verbose
	-m	Max time-to-live (max number of hops)
	-p	Base UDP port number used in probes
		(default 33434)
	-q	Number of probes per TTL (default 3)
	-s	IP address to use as the source address
	-t	Type-of-service in probe packets (default 0)
	-w	Time in seconds to wait for a response (default 3)
	-g	Loose source route gateway (8 max)
```

<a id="a-true"></a>

## `true`

```
Usage: true 

Return an exit code of TRUE (0)
```

<a id="a-tty"></a>

## `tty`

```
Usage: tty 

Print file name of stdin's terminal

	-s	Print nothing, only return exit status
```

<a id="a-ttysize"></a>

## `ttysize`

```
Usage: ttysize [w] [h]

Print dimension(s) of stdin's terminal, on error return 80x25
```

<a id="a-tunctl"></a>

## `tunctl`

```
Usage: tunctl [-f device] ([-t name] | -d name) [-u owner] [-g group] [-b]

Create or delete tun interfaces

	-f name		tun device (/dev/net/tun)
	-t name		Create iface 'name'
	-d name		Delete iface 'name'
	-u owner	Set iface owner
	-g group	Set iface group
	-b		Brief output
```

<a id="a-tune2fs"></a>

## `tune2fs`

```
Usage: tune2fs [-c MOUNT_CNT] [-i DAYS] [-L LABEL] BLOCKDEV

Adjust filesystem options on ext[23] filesystems
```

<a id="a-udhcpc"></a>

## `udhcpc`

```
Usage: udhcpc [-fbnqvoCRB] [-i IFACE] [-r IP] [-s PROG] [-p PIDFILE]
	[-H HOSTNAME] [-V VENDOR] [-x OPT:VAL]... [-O OPT]... [-P N]

	-i,--interface IFACE	Interface to use (default eth0)
	-p,--pidfile FILE	Create pidfile
	-s,--script PROG	Run PROG at DHCP events (default /usr/share/udhcpc/default.script)
	-B,--broadcast		Request broadcast replies
	-t,--retries N		Send up to N discover packets
	-T,--timeout N		Pause between packets (default 3 seconds)
	-A,--tryagain N		Wait N seconds after failure (default 20)
	-f,--foreground		Run in foreground
	-b,--background		Background if lease is not obtained
	-n,--now		Exit if lease is not obtained
	-q,--quit		Exit after obtaining lease
	-R,--release		Release IP on exit
	-S,--syslog		Log to syslog too
	-P,--client-port N	Use port N (default 68)
	-a,--arping		Use arping to validate offered address
	-O,--request-option OPT	Request option OPT from server (cumulative)
	-o,--no-default-options	Don't request any options (unless -O is given)
	-r,--request IP		Request this IP address
	-x OPT:VAL		Include option OPT in sent packets (cumulative)
				Examples of string, numeric, and hex byte opts:
				-x hostname:bbox - option 12
				-x lease:3600 - option 51 (lease time)
				-x 0x3d:0100BEEFC0FFEE - option 61 (client id)
	-F,--fqdn NAME		Ask server to update DNS mapping for NAME
	-H,-h,--hostname NAME	Send NAME as client hostname (default none)
	-V,--vendorclass VENDOR	Vendor identifier (default 'udhcp VERSION')
	-C,--clientid-none	Don't send MAC as client identifier
	-v			Verbose
Signals:
	USR1	Renew current lease
	USR2	Release current lease
```

<a id="a-udhcpd"></a>

## `udhcpd`

```
Usage: udhcpd [-fS] [-P N] [CONFFILE]

DHCP server

	-f	Run in foreground
	-S	Log to syslog too
	-P N	Use port N (default 67)
```

<a id="a-umount"></a>

## `umount`

```
Usage: umount [OPTIONS] FILESYSTEM|DIRECTORY

Unmount file systems

	-a	Unmount all file systems
	-r	Try to remount devices as read-only if mount is busy
	-l	Lazy umount (detach filesystem)
	-f	Force umount (i.e., unreachable NFS server)
	-d	Free loop device if it has been used
```

<a id="a-uname"></a>

## `uname`

```
Usage: uname [-amnrspv]

Print system information

	-a	Print all
	-m	The machine (hardware) type
	-n	Hostname
	-r	OS release
	-s	OS name (default)
	-p	Processor type
	-v	OS version
```

<a id="a-unexpand"></a>

## `unexpand`

```
Usage: unexpand [-fa][-t N] [FILE]...

Convert spaces to tabs, writing to stdout

	-a,--all	Convert all blanks
	-f,--first-only	Convert only leading blanks
	-t,--tabs=N	Tabstops every N chars
```

<a id="a-uniq"></a>

## `uniq`

```
Usage: uniq [-cdu][-f,s,w N] [INPUT [OUTPUT]]

Discard duplicate lines

	-c	Prefix lines by the number of occurrences
	-d	Only print duplicate lines
	-u	Only print unique lines
	-f N	Skip first N fields
	-s N	Skip first N chars (after any skipped fields)
	-w N	Compare N characters in line
```

<a id="a-unix2dos"></a>

## `unix2dos`

```
Usage: unix2dos [-ud] [FILE]

Convert FILE in-place from Unix to DOS format.
When no file is given, use stdin/stdout.

	-u	dos2unix
	-d	unix2dos
```

<a id="a-unlzop"></a>

## `unlzop`

```
Usage: unlzop [-cfvCF] [FILE]...

	-c	Write to stdout
	-f	Force
	-v	Verbose
	-F	Don't store or verify checksum
```

<a id="a-uptime"></a>

## `uptime`

```
Usage: uptime 

Display the time since the last boot
```

<a id="a-users"></a>

## `users`

```
Usage: users 

Print the users currently logged on
```

<a id="a-usleep"></a>

## `usleep`

```
Usage: usleep N

Pause for N microseconds
```

<a id="a-vconfig"></a>

## `vconfig`

```
Usage: vconfig COMMAND [OPTIONS]

Create and remove virtual ethernet devices

	add		[interface-name] [vlan_id]
	rem		[vlan-name]
	set_flag	[interface-name] [flag-num] [0 | 1]
	set_egress_map	[vlan-name] [skb_priority] [vlan_qos]
	set_ingress_map	[vlan-name] [skb_priority] [vlan_qos]
	set_name_type	[name-type]
```

<a id="a-vi"></a>

## `vi`

```
Usage: vi [OPTIONS] [FILE]...

Edit FILE

	-c	Initial command to run ($EXINIT also available)
	-R	Read-only
	-H	Short help regarding available features
```

<a id="a-vlock"></a>

## `vlock`

```
Usage: vlock [-a]

Lock a virtual terminal. A password is required to unlock.

	-a	Lock all VTs
```

<a id="a-volname"></a>

## `volname`

```
Usage: volname [DEVICE]

Show CD volume name of the DEVICE (default /dev/cdrom)
```

<a id="a-watch"></a>

## `watch`

```
Usage: watch [-n SEC] [-t] PROG ARGS

Run PROG periodically

	-n	Loop period in seconds (default 2)
	-t	Don't print header
```

<a id="a-watchdog"></a>

## `watchdog`

```
Usage: watchdog [-t N[ms]] [-T N[ms]] [-F] DEV

Periodically write to watchdog device DEV

	-T N	Reboot after N seconds if not reset (default 60)
	-t N	Reset every N seconds (default 30)
	-F	Run in foreground

Use 500ms to specify period in milliseconds
```

<a id="a-wc"></a>

## `wc`

```
Usage: wc [-cmlwL] [FILE]...

Count lines, words, and bytes for each FILE (or stdin)

	-c	Count bytes
	-m	Count characters
	-l	Count newlines
	-w	Count words
	-L	Print longest line length
```

<a id="a-wget"></a>

## `wget`

```
Usage: wget [-c|--continue] [-s|--spider] [-q|--quiet] [-O|--output-document FILE]
	[--header 'header: value'] [-Y|--proxy on/off] [-P DIR]
	[--no-check-certificate] [-U|--user-agent AGENT] [-T SEC] URL...

Retrieve files via HTTP or FTP

	-s	Spider mode - only check file existence
	-c	Continue retrieval of aborted transfer
	-q	Quiet
	-P DIR	Save to DIR (default .)
	-T SEC	Network read timeout is SEC seconds
	-O FILE	Save to FILE ('-' for stdout)
	-U STR	Use STR for User-Agent header
	-Y	Use proxy ('on' or 'off')
```

<a id="a-which"></a>

## `which`

```
Usage: which [COMMAND]...

Locate a COMMAND
```

<a id="a-who"></a>

## `who`

```
Usage: who [-a]

Show who is logged on

	-a	Show all
```

<a id="a-whoami"></a>

## `whoami`

```
Usage: whoami 

Print the user name associated with the current effective user id
```

<a id="a-xargs"></a>

## `xargs`

```
Usage: xargs [OPTIONS] [PROG ARGS]

Run PROG on every item given by stdin

	-p	Ask user whether to run each command
	-r	Don't run command if input is empty
	-0	Input is separated by NUL characters
	-t	Print the command on stderr before execution
	-e[STR]	STR stops input processing
	-n N	Pass no more than N args to PROG
	-s N	Pass command line of no more than N bytes
	-x	Exit if size is exceeded
```

<a id="a-yes"></a>

## `yes`

```
Usage: yes [STRING]

Repeatedly output a line with STRING, or 'y'
```

<a id="a-zcat"></a>

## `zcat`

```
Usage: zcat FILE

Decompress to stdout
```

<a id="a-zcip"></a>

## `zcip`

```
Usage: zcip [OPTIONS] IFACE SCRIPT

Manage a ZeroConf IPv4 link-local address

	-f		Run in foreground
	-q		Quit after obtaining address
	-r 169.254.x.x	Request this address first
	-v		Verbose

With no -q, runs continuously monitoring for ARP conflicts,
exits only on I/O errors (link down etc)
```
