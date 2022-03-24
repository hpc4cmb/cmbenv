#!/bin/bash

pkg="cfitsio"
pkgopts=$@
cleanup=""

version=4.1.0
pdir=cfitsio-${version}
pfile=${pdir}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stderr
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf ${pdir}
tar xzf ${src} \
    && cd ${pdir} \
    && cleanup="${cleanup} $(pwd)" \
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
