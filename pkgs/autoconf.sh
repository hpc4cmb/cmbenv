#!/bin/bash

pkg="autoconf"
pkgopts=$@
cleanup=""

pfile=autoconf-2.69.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://ftp.gnu.org/gnu/autoconf/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

rm -rf autoconf-2.69
tar xzf ${src} \
    && cd autoconf-2.69 \
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
