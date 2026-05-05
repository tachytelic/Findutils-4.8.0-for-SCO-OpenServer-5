# GNU findutils 4.8.0 for SCO OpenServer 5

A working build of [GNU findutils 4.8.0](https://www.gnu.org/software/findutils/)
(January 2021) for **SCO OpenServer 5.0.7**. Provides `gfind`, `gxargs`,
`glocate`, `gupdatedb` — `g`-prefixed so they don't shadow SCO's stock
`/bin/find` and `/bin/xargs`.

```
$ gfind --version
find (GNU findutils) 4.8.0

$ gfind /etc -mtime -7 -name '*.conf'           # files modified in last 7 days
$ gfind . -size +1M -printf '%p %s\n'           # files >1MB with size
$ gfind /var/log -name '*.log' -print0 | gxargs -0 wc -l
$ gfind /tmp -newer /etc/passwd -delete         # safe deletion
```

## Why?

SCO's `/bin/find` is the original SVR4 find — no `-printf`, `-print0`,
`-regex`, `-mtime` with units beyond plain days, no `-newermt`. Stock
`xargs` lacks `-0`/`-r`/`-I` proper. Most modern shell idioms break.

GNU findutils gives you the full toolkit:

- `gfind -printf` — format output any way you like (`%p`, `%s`, `%T@`, `%M`)
- `gfind -print0` paired with `gxargs -0` — handle filenames with spaces/newlines safely
- `gfind -regex` / `-iregex` — regex matching (basic, extended, awk, posix)
- `gfind -newer{,m,a,c}{m,a,c,t}` — granular time comparison
- `gfind -delete` — built-in deletion (no spawn-per-file via `-exec rm`)
- `glocate` + `gupdatedb` — fast filesystem index
- `gxargs -r` — don't run with empty input
- `gxargs -I {}` — substitute filename anywhere in command

## Install

> **Fresh SCO box?** Install [curl with TLS](https://github.com/tachytelic/curl-7.88.1-for-SCO-OpenServer-5)
> first.

```sh
# On the SCO box:
curl -LO https://github.com/tachytelic/Findutils-4.8.0-for-SCO-OpenServer-5/releases/download/v1.0.0/findutils-4.8.0-sco.tar.gz
gtar xzf findutils-4.8.0-sco.tar.gz
mv install /usr/local/findutils-4.8.0
export PATH=/usr/local/findutils-4.8.0/bin:$PATH
```

To use `find`/`xargs` instead of the g-prefixed names, alias in
`~/.profile`:

```sh
alias find=gfind
alias xargs=gxargs
alias locate=glocate
```

## Building from source

```sh
cd findutils-sco
./build.sh
```

Or with a non-default GCC:

```sh
GCC=/path/to/gcc-3.4 ./build.sh
```

### What the patches do

`patches/findutils-4.8.0-sco.patch` is a 53-line diff with four hunks:

1. **`gl/lib/unistd.in.h`** — skip gnulib's `gethostname` redeclaration
   (gnulib uses `size_t`, SCO has `int`). Same fix as our other gnulib-
   based builds.
2. **`gl/lib/getprogname.c`** — `#error` → `return "?"` for unrecognised
   OSes.
3. **`gl/lib/gethostname.c`** — match SCO's `int len` signature.
4. **`lib/buildcmd.c`** — suppress an unconditional `#error` block that
   fires when `NCARGS` is defined but `ARG_MAX` isn't (which happens on
   SCO). The code path it gates is correct and fine; the error message
   just wants you to confirm before running. We confirm by removing it.

Note that gnulib in findutils lives in `gl/lib/`, not `lib/` —
findutils' own library code is in `lib/`. Our patches target both.

## Repository layout

```
patches/
  findutils-4.8.0-sco.patch   53 lines, 4 hunks
build.sh                      Native-build script (run on SCO)
LICENSE                       MIT (covers patch + build script)
README.md                     This file
```

The prebuilt 430 KB tarball ships via the
**[Releases](../../releases)** page.

## License

GNU findutils is © Free Software Foundation, distributed under
[GPLv3+](https://www.gnu.org/licenses/gpl-3.0.html). The prebuilt
binaries are unmodified upstream findutils 4.8.0 with the patches in
this repo applied. The patches and build script are released under MIT.

## See also

- [curl-7.88.1 for SCO](https://github.com/tachytelic/curl-7.88.1-for-SCO-OpenServer-5)
  — the natural first install on a fresh SCO box.
- [GNU coreutils 8.32 for SCO](https://github.com/tachytelic/Coreutils-8.32-for-SCO-OpenServer-5),
  [GNU grep 3.7 for SCO](https://github.com/tachytelic/Grep-3.7-for-SCO-OpenServer-5),
  [GNU gawk 5.1.1 for SCO](https://github.com/tachytelic/Gawk-5.1.1-for-SCO-OpenServer-5)
  — sibling builds.
- [More SCO OpenServer 5 binaries](https://tachytelic.net/2017/07/sco-openserver-5-binaries/)
  — the hub.
