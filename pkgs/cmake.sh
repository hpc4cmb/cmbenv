#!/bin/bash

pkg="cmake"
pkgopts=$@
cleanup=""

version=3.21.3
pfile=cmake-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/Kitware/CMake/releases/download/v${version}/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log="/dev/stdout"
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf cmake-${version}
tar xzf ${src} \
    && cd cmake-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@BUILD_CC@" CXX="@BUILD_CXX@" \
    ./configure --prefix="@AUX_PREFIX@" -- \
    -DCMAKE_USE_OPENSSL=OFF > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
