#!/bin/bash

pkg="m4"
pkgopts=$@
cleanup=""

pfile=m4-1.4.18.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://ftp.gnu.org/gnu/m4/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

rm -rf m4-1.4.18
tar xjf ${src} \
    && cd m4-1.4.18 \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_m4" > ${log} 2>&1 \
    && CC="@BUILD_CC@" ./configure --prefix="@AUX_PREFIX@" >> ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
