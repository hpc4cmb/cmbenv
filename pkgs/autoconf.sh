#!/bin/bash

pkg="autoconf"
pkgopts=$@
cleanup=""

version=2.69
pfile=autoconf-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://ftp.gnu.org/gnu/autoconf/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf autoconf-${version}
tar xzf ${src} \
    && cd autoconf-${version} \
    && cleanup="${cleanup} $(pwd)" \
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
