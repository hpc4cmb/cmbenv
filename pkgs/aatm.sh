#!/bin/bash

pkg="aatm"
pkgopts=$@
cleanup=""

version=1.0.8
pfile=libaatm-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/libaatm/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf libaatm-${version}
tar xzf ${src} \
    && cd libaatm-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
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
