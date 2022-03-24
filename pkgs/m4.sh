#!/bin/bash

pkg="m4"
pkgopts=$@
cleanup=""

version=1.4.19
pfile=m4-${version}.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://ftpmirror.gnu.org/m4/${pfile} ${pfile})

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

rm -rf m4-${version}
tar xjf ${src} \
    && cd m4-${version} \
    && cleanup="${cleanup} $(pwd)" \
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
