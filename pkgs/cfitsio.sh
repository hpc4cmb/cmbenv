#!/bin/bash

pkg="cfitsio"
pkgopts=$@
cleanup=""

pfile=cfitsio3450.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf cfitsio
tar xzf ${src} \
    && cd cfitsio \
    && CC="@CC@" CFLAGS="@CFLAGS@" ./configure @CROSS@ \
    --prefix="@AUX_PREFIX@" --enable-reentrant > ${log} 2>&1 \
    && make stand_alone >> ${log} 2>&1 \
    && make utils >> ${log} 2>&1 \
    && make shared >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
