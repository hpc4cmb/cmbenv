#!/bin/bash

pkg="tidas"
pkgopts=$@
cleanup=""

pfile=tidas-0.3.3.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/tidas/archive/0.3.3.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf tidas-0.3.3
tar xzf ${src} \
    && cd tidas-0.3.3 \
    && mkdir build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@MPICC@" \
    -DCMAKE_CXX_COMPILER="@MPICXX@" \
    -DMPI_C_COMPILER="@MPICC@" \
    -DMPI_CXX_COMPILER="@MPICXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@ -pthread -DSQLITE_DISABLE_INTRINSIC" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@ -pthread -DSQLITE_DISABLE_INTRINSIC" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DPYTHON_EXECUTABLE:FILEPATH="@PYTHON_PREFIX@/bin/python" \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    .. > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
