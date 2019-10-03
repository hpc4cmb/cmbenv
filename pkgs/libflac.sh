#!/bin/bash

pkg="libflac"
pkgopts=$@
cleanup=""

version=1.3.3
pfile=flac-${version}.tar.xz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://ftp.osuosl.org/pub/xiph/releases/flac/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf flac-${version}
tar xJf ${src} \
    && cd flac-${version} \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    ./configure @CROSS@ --disable-cpplibs \
    --disable-ogg --disable-xmms-plugin \
    --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
