#!/bin/bash

pkg="uncrustify"
pkgopts=$@
cleanup=""

version=0.73.0
pfile=uncrustify-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/uncrustify/uncrustify/archive/refs/tags/${pfile} ${pfile})

# Yes, this is silly
srcdir=uncrustify-uncrustify-${version}

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log="/dev/stdout"
else
    log="../../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf ${srcdir}
tar xzf ${src} \
    && cd ${srcdir} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@BUILD_CC@" \
    -DCMAKE_CXX_COMPILER="@BUILD_CXX@" \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    .. > "${log}" 2>&1 \
    && make -j @MAKEJ@ >> "${log}" 2>&1 \
    && make install >> "${log}" 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
