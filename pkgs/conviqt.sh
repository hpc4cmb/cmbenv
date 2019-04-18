#!/bin/bash

pkg="conviqt"
pkgopts=$@
cleanup=""

pfile=libconviqt-1.1.0.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://www.dropbox.com/s/11r3pj4wntnqax1/libconviqt-1.1.0.tar.bz2?dl=1 ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf libconviqt-1.1.0
tar xjf ${src} \
    && cd libconviqt-1.1.0 \
    && CC="@MPICC@" CXX="@MPICXX@" MPICC="@MPICC@" MPICXX="@MPICXX@" \
    CFLAGS="@CFLAGS@ -std=gnu99" CXXFLAGS="@CXXFLAGS@" \
    ./configure @CROSS@ \
    --with-cfitsio="@AUX_PREFIX@" --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1 \
    && cd python \
    && python setup.py install --prefix "@AUX_PREFIX@" >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
