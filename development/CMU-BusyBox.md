# CMU BusyBox: the version to target and its limits

Use this page when you write or review a worker: it says what the CMU's BusyBox is and which commands,
options and shell features it has and lacks.

## What BusyBox is

BusyBox ([busybox.net](https://busybox.net/about.html)) is "the Swiss Army Knife of Embedded Linux": it
puts tiny versions of many common UNIX tools (`ls`, `cp`, `grep`, `sed`, `tar`, a shell and so on) into
one small executable, as a replacement for most of GNU fileutils, shellutils and similar packages.

Each tool inside it is called an *applet*; BusyBox keeps only some of the GNU options and is built with a
chosen set of applets and features.

## BusyBox in the CMU

On the CMU the shell and the everyday command-line tools (`sh`, `ls`, `grep`, `sed` and so on) are
BusyBox. The program is the single file `/bin/busybox`, and the names of the applets are links to it, so a
command typed in a terminal on the CMU or called from a script runs this BusyBox.

| Item | Value |
| --- | --- |
| Build | ARM, dynamically linked, glibc 2.11.1; 274 applets; `/bin/sh` is the BusyBox shell `ash` |

### Which version

Run this in a shell on the CMU:

```sh
/bin/busybox | head -n 1
```

It prints one line, the version banner:

```text
BusyBox v1.19.2 (2020-02-14 18:04:06 JST) multi-call binary.
```

The version is `1.19.2`.

Without `| head -n 1` the command also
prints the usage text and the list of all applets. The same banner starts the `--help` of any applet, for
example `ls --help`.

### What it depends on

BusyBox on the CMU is dynamically linked: it does not carry the C library code inside itself, it uses
shared libraries that are installed on the CMU. It needs a loader (the program that loads the libraries
and starts BusyBox) and two libraries. Without them it does not start.

The BusyBox file asks for them by general names. On the CMU each name is a link to the real file:

| Name BusyBox asks for | What it is | Real file on the CMU |
| --- | --- | --- |
| `/lib/ld-linux.so.3` | the loader | `/lib/ld-2.11.1.so` |
| `libm.so.6` | the math library | `/lib/libm-2.11.1.so` |
| `libc.so.6` | the C library | `/lib/libc-2.11.1.so` |

The libraries are glibc, the GNU C library; the number `2.11.1` in the file names is its version.

**How to find the names.** The list is stored inside the BusyBox file, and the CMU has no tool to read it
(there is no `readelf`). Copy `/bin/busybox` from the CMU to a PC and run there:

```sh
readelf -l busybox | grep interpreter
readelf -d busybox | grep NEEDED
```

```text
      [Requesting program interpreter: /lib/ld-linux.so.3]
 0x00000001 (NEEDED)                     Shared library: [libm.so.6]
 0x00000001 (NEEDED)                     Shared library: [libc.so.6]
```

The first command shows the loader (`interpreter`), the second the libraries (`NEEDED`).

**How to find the real files.** Run on the CMU:

```sh
ls -l /lib/ld-linux.so.3 /lib/libm.so.6 /lib/libc.so.6
```

```text
lrwxrwxrwx    1 0        0               12 Jan  1 00:01 /lib/ld-linux.so.3 -> ld-2.11.1.so
lrwxrwxrwx    1 0        0               14 Jan  1 00:01 /lib/libm.so.6 -> libm-2.11.1.so
lrwxrwxrwx    1 0        0               14 Jan  1 00:01 /lib/libc.so.6 -> libc-2.11.1.so
```

The letter `l` at the start of each line means a link; the name after `->` is the real file.

### Which applets it has

BusyBox is built from a configuration file (`.config`) that switches each applet and feature on or off.
We do not know the configuration this BusyBox was built with; we only have the result: its applets
(`busybox --list`) and the options of each (`applet --help`, for example `ls --help`).

`busybox --list` prints the names of the 274 applets compiled into this build. The list, with the
`--help` of each applet, is in the [applet reference](CMU-BusyBox-reference.md).


## Compared with the BusyBox 1.19.2 source

This BusyBox is presumably based on the BusyBox 1.19.2 source, built with a configuration we do not
know. We compared it with that source, with every applet and feature switched on: the CMU build has no
applet and no option that the source lacks; it only has fewer of them. So the 1.19.2 source is a
reliable guide to what a command can do, and the CMU binary decides which of those it actually has.

There is no web manual for 1.19.2. Use the `--help` of the applet on the CMU or in the
[applet reference](CMU-BusyBox-reference.md).

## Shell (`ash`)

Works: POSIX sh, `local`, arithmetic `$(( ))` including `**`, `?:`, `<<`, `x++`; `${v#p} ${v%p}
${v:-d} ${v:=d} ${v:+a} ${#v}`; also `${v:1:2}`, `${v/x/y}`, `${v//x/y}`; `[[ a = b ]]` with plain
comparison; `source`; `read -r -n -t -s -p`; `<<-`; `&>`; `set -e -u -o pipefail`; `trap` on EXIT and
signals; `getopts`; `$'..'`; `$RANDOM $PPID $$ $!`; `exec 3>file`. Prefer POSIX forms anyway; the
extras exist only because this build enabled them.

Does not work (write a POSIX equivalent):

- arrays `a=(1 2)`, `${a[1]}`, `${PIPESTATUS[0]}`; `declare`, `typeset`
- `[[ x == glob* ]]` gives no error but is always false; `[[ x =~ re ]]` is an error. Use `case`
- `<<<` here-strings, `<(...)` process substitution
- `function name { }`, `for ((i=0;i<n;i++))`, `select`
- brace expansion: `{a,b}` and `{1..3}` stay as they are
- `${!name}`, `${v^^}`, `printf %q`, `printf -v` (it prints `-v` and sets nothing)
- `trap ... ERR`, `wait -n`
- the variables `$LINENO $HOSTNAME $SECONDS $UID $OSTYPE` are empty or unset

## Which program a command name runs

The CMU build has 274 of the 388 applets that BusyBox 1.19.2 offers; the 114 it lacks are listed
[below](#busybox-1192-applets-this-build-leaves-out).

A name in a script does not always run the BusyBox applet of that name. The shell's own built-in
commands come first; then the directories of `PATH` are searched in order, and the first file found
runs. In a tweak `PATH` is
`/sbin:/usr/sbin:/bin:/usr/bin:/jci/bin/:/resources/dev/bin:/resources/dev/sbin:/data_persist/dev/bin:/data_persist/dev/sbin:/resources/dev/usr/bin`.

What each name runs in a tweak on firmware 74.00.324 (`command -v NAME` on the vehicle):

| Runs | Names |
| --- | --- |
| a built-in command of `ash`, not the applet whose `--help` is in the reference | `[ [[ echo false kill printf pwd test true` |
| BusyBox | the other 258 applets, including `chattr` and `lsattr` (the e2fsprogs copies in `/usr/bin` come after `/bin` in `PATH`) |
| another program, although BusyBox has an applet with the name | `ip` (iproute2), `blkid`, `findfs`, `mke2fs`, `mkfs.ext2`, `tune2fs` (e2fsprogs), `passwd` (the script `/jci/scripts/jci-passwd.sh`) |
| a separate program | `unzip`, `zip`, `curl`, `openssl`, `sqlite3`, `strace`, `lua`, `luac`, `ssh`, `sshd`, `dbus-send`, `dbus-daemon`, `i2cget`, `chat`, `tc`; `e2fsck`, `fsck.ext2`, `fsck.ext3`, `mkfs.ext3` (e2fsprogs) |
| nothing: not on the CMU | `sha1sum sha256sum sha512sum` (use `md5sum`, `cksum` or `sum`), `xz xzcat unxz lzma` (use `gzip`, `bzip2` or `lzop`), `uuencode uudecode`, `start-stop-daemon`, `telnet tftp ftpget`, `crond crontab`, `ar`, `dc`, `mesg`, `ping6`, `bash`, `hush`, `xxd` (use `od` or `hexdump -C`), `truncate` (use `dd`), `paste`, `nl`, `join`, `nproc`, `shuf`, `factor`, `bc`, `numfmt`, `link`, `unlink`, `lsof`, `ts`, `whereis`, `unshare`, `nsenter`, `setpriv`, `lockfile`, `sysinfo`, `readelf`, `ldd`, `objdump`, `python`, `python3`, `perl` |

A separate program has its own options, not the ones in the reference: `ip` takes iproute2 options;
use `busybox ip` for the applet. `curl` has no SSL support, so it cannot fetch `https://` addresses.

To check a name yourself, use `command -v NAME` on the CMU: a bare name means a built-in command, a
path means a program (`ls -l PATH` shows whether it is a link to `/bin/busybox`).

### BusyBox 1.19.2 applets this build leaves out

The source of BusyBox 1.19.2 has 388 applets; the CMU build has 274 of them. Of the 114 it leaves out,
21 names exist on the CMU as separate programs, with their own options (not BusyBox):
`chat` `e2fsck` `e2label` `flash_eraseall` `flash_lock` `flash_unlock` `flashcp` `fsck.ext2` `fsck.ext3` `init` `mkfs.ext3` `nanddump` `nandwrite` `tc` `ubiattach` `ubidetach` `ubimkvol` `ubirmvol` `ubirsvol` `ubiupdatevol` `unzip`.

The other 93 do not exist on the CMU at all, so a script cannot use them:
`acpid` `ar` `bash` `bbconfig` `beep` `bootchartd` `chcon` `chpst` `conspy` `crond` `crontab` `dc` `devfsd` `dnsd` `dpkg` `dpkg-deb` `envdir` `envuidgid` `ether-wake` `fakeidentd` `freeramdisk` `fsck.minix` `ftpd` `ftpget` `ftpput` `getenforce` `getsebool` `hush` `inotifyd` `length` `linuxrc` `load_policy` `loadfont` `lpd` `lpq` `lpr` `lzcat` `lzma` `makemime` `man` `matchpathcon` `mesg` `microcom` `mkdosfs` `mkfs.minix` `mkfs.reiser` `mkfs.vfat` `msh` `mt` `parse` `ping6` `pivot_root` `popmaildir` `raidautorun` `readahead` `reformime` `restorecon` `rfkill` `runcon` `runlevel` `runsv` `runsvdir` `selinuxenabled` `sendmail` `sestatus` `setenforce` `setfiles` `setsebool` `setserial` `setuidgid` `sha1sum` `sha256sum` `sha512sum` `softlimit` `start-stop-daemon` `sv` `svlogd` `switch_root` `telnet` `telnetd` `tftp` `tftpd` `traceroute6` `udpsvd` `uncompress` `unlzma` `unxz` `uudecode` `uuencode` `wall` `whois` `xz` `xzcat`

## Options that behave differently

The [applet reference](CMU-BusyBox-reference.md) has the `--help` of every applet. An option listed
there exists. `--help` does not show every option an applet accepts, though: `grep -a`, `diff -u` and
`xargs -E`, for example, are accepted although they are not listed. Do not rely on an option that is
not listed; it may be accepted and do nothing.

These options exist, but do not work as their help or habit suggests:

| Applet | Behavior | Use instead |
| --- | --- | --- |
| `awk` | `-F'\t'` does not split on tab; `length(array)` returns 0 | `-F"$(printf '\t')"`; count in a loop |
| `sed` | `-i` takes no suffix (`-i.bak` is an error) | copy the file first |
| `date` | `-d` needs `YYYY-MM-DD HH:MM[:SS]` or `@epoch`; no `-d 2020-01-02`, no `yesterday` | `date -D FORMAT -d STRING`, or add `00:00:00` |
| `touch` | `-d 2020-01-02` needs the time part | `touch -d "2020-01-02 00:00:00"` |
| `timeout` | `timeout 5 cmd` fails (it tries to run `5`); without `-t` the default is 10 s | `timeout -t 5 cmd`, `timeout -t 5 -s KILL cmd` |
| `patch` | `--help` lists `--strip --input --reverse --forward --remove-empty-files`, but every long option is rejected | `-p -i -R -N -E` |
| `test` | `test --help` prints nothing: `--help` is just an expression | |

## Known bugs

Bugs of this BusyBox, not missing options. All but the last were found with the official BusyBox 1.19.2
testsuite; the last was found in the emulator and confirmed on the vehicle:

- `grep` ends a line at a NUL byte: `grep .` does not match a line that contains only NUL.
- `sed '/x/a text'` on input without a final newline glues the text to the last line (`wootwoo`).
- `sed 'n;p'` prints the last line twice.
- `sed 's/[[:space:]]*/,/g'` on `12345` gives `,12345`; empty matches are not repeated.
- `sed -e 'b label'` with a label that does not exist and empty input exits 0 silently; the error
  appears only when a line is processed.
- `sed` with a NUL byte in the input (`s/woo/bang/` on `\0woo\0woo\0`) replaces in every NUL-separated
  piece, and a NUL inside a script file is not handled.
- `sort -k2,3rn` and `sort -k2,3n -r` order numeric key ranges differently from what the 1.19.2 testsuite expects.
- `cpio -t` does not list every name of a hard-linked file.
- `printf` with a conversion (`%s`, `%d`, ...) can return exit status 1 although it printed
  correctly. It happens when its output is the first output of the process and goes to `/dev/null` (or
  another device that is not a terminal): `printf "%s" a >/dev/null` returns 1, a second such call
  returns 0, and output to a file, a pipe or `$(...)` returns 0. The cause: BusyBox `printf` treats any
  `errno` left after printing as an error, and the C library sets one when it checks whether the
  output is a terminal. This happens on the vehicle too. Do not test the status of a `printf` whose
  output may go to `/dev/null`; if you redirect it there, write `printf ... >/dev/null || :`.

## USB stick limits

The USB stick (FAT, mounted at `/tmp/mnt/sdb1`) does not allow symlinks, hard links, `mkfifo` or a
file name with `:`. Do not create them on the stick; use `/tmp` for scratch space.

## Open questions

> [!WARNING]
> ⚠️ **Not verified yet (note for maintainers).**
>
> - `PATH` in the CMU terminal may differ from the one in a tweak (above); it has not been recorded.
> - The table of what each name runs comes from one vehicle. `/resources/dev/*` does not exist on it
>   and `/data_persist/dev/bin` and `/data_persist/dev/sbin` are empty. On another vehicle a program
>   there runs for any name that the system directories do not have, for example `sha256sum`; it cannot
>   replace a system command, because those directories come last in `PATH`.
