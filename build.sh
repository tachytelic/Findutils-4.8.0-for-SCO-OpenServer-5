#!/bin/sh
# Build GNU findutils 4.8.0 natively on SCO OpenServer 5.0.7.
#
# Output: ./install/bin/{gfind,gxargs,glocate,gupdatedb} — g-prefixed
# to coexist with SCO's stock /bin/find and /bin/xargs.

set -e

SCRIPT_DIR=`cd \`dirname "$0"\` && pwd`
VERSION=4.8.0
TARBALL=findutils-${VERSION}.tar.gz
SRCDIR=findutils-${VERSION}

CC="${GCC:-${CC:-gcc}}"
export CC
PATH=/usr/gnu/bin:/usr/ccs/bin:/usr/bin:/bin
export PATH

if [ ! -f "$TARBALL" ]; then
    if which wget >/dev/null 2>&1; then
        # gnu.org ships findutils as .tar.xz; SCO has no xz.
        # Either drop the .tar.gz here yourself, or convert on a Linux box.
        wget --no-check-certificate "https://ftp.gnu.org/gnu/findutils/findutils-${VERSION}.tar.xz" 2>/dev/null || true
        if [ -f "findutils-${VERSION}.tar.xz" ]; then
            echo "Got .tar.xz — convert on Linux: xz -d -c file.tar.xz | gzip > file.tar.gz" >&2
            exit 1
        fi
    fi
    if [ ! -f "$TARBALL" ]; then
        echo "ERROR: drop $TARBALL next to this script." >&2
        exit 1
    fi
fi

if [ ! -d "$SRCDIR" ]; then
    /usr/bin/gunzip -c "$TARBALL" | /usr/bin/tar xf -
fi

cd "$SRCDIR"

if [ ! -f .sco_patched ]; then
    echo "Applying SCO compatibility patch..."
    /usr/bin/patch -p1 < "$SCRIPT_DIR/patches/findutils-${VERSION}-sco.patch"
    touch .sco_patched
fi

SHELL_BIN=`which bash 2>/dev/null`
if [ -z "$SHELL_BIN" ]; then
    echo "ERROR: bash required as configure shell." >&2; exit 1
fi

echo "Configuring..."
FORCE_UNSAFE_CONFIGURE=1 CONFIG_SHELL=$SHELL_BIN $SHELL_BIN configure \
    --prefix="$SCRIPT_DIR/install" \
    --program-prefix=g \
    --disable-nls \
    CC="$CC" \
    CFLAGS="-O2 -std=gnu99"

# Patches modify gl/lib/unistd.in.h; force regen of gl/lib/unistd.h.
rm -f gl/lib/unistd.h

echo "Compiling..."
gmake

echo "Installing to $SCRIPT_DIR/install/..."
gmake install

echo "Stripping..."
find "$SCRIPT_DIR/install" -type f -perm -u+x -exec strip {} \; 2>/dev/null || true

ls -l "$SCRIPT_DIR/install/bin/"
echo
echo "Test it:"
echo "  $SCRIPT_DIR/install/bin/gfind /etc -maxdepth 1 -name 'host*' -printf '%p (%s bytes)\\n'"
echo
echo "To package: gtar czf findutils-${VERSION}-sco.tar.gz install"
