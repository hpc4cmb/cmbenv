#!/bin/bash

pkg="bzip2"
pkgopts=$@
cleanup=""

# NOTE:  change URL when changing version
version=1.0.6

pfile=bzip2_${version}.orig.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/bzip2/${version}-8/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stdout
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf bzip2-${version}
tar xjf ${src} \
    && cd bzip2-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_bzip2" > ${log} 2>&1 \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    make -f Makefile-toast >> ${log} 2>&1 \
    && cp -a bzlib.h "@AUX_PREFIX@/include" \
    && cp -a libbz2.so* "@AUX_PREFIX@/lib"

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
