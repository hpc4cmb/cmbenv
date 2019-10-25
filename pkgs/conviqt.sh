#!/bin/bash

pkg="conviqt"
pkgopts=$@
cleanup=""

version=1.2.1
pfile=libconviqt-${version}.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/libconviqt/releases/download/v${version}/libconviqt-${version}.tar.bz2 ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf libconviqt-${version}
tar xjf ${src} \
    && cd libconviqt-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@MPICC@" CXX="@MPICXX@" MPICC="@MPICC@" MPICXX="@MPICXX@" \
    CFLAGS="@CFLAGS@ -std=gnu99" CXXFLAGS="@CXXFLAGS@" \
    OPENMP_CFLAGS="@OPENMP_CFLAGS@" OPENMP_CXXFLAGS="@OPENMP_CXXFLAGS@" \
    LDFLAGS="@LDFLAGS@" \
    ./configure @CROSS@ \
    --with-cfitsio="@AUX_PREFIX@" --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1 \
    && cd python \
    && python3 setup.py install --prefix "@AUX_PREFIX@" >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
