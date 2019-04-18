#!/bin/bash

pkg="fftw"
pkgopts=$@
cleanup=""

pfile=fftw-3.3.8.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://www.fftw.org/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf fftw-3.3.8
tar xzf ${src} \
    && cd fftw-3.3.8 \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    ./configure --enable-threads @CROSS@ \
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
