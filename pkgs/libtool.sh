#!/bin/bash

pkg="libtool"
pkgopts=$@
cleanup=""

pfile=libtool-2.4.6.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://ftp.gnu.org/gnu/libtool/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

rm -rf libtool-2.4.6
tar xzf ${src} \
    && cd libtool-2.4.6 \
    && CC="@BUILD_CC@" ./configure --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
