#!/bin/bash

pkg="toast"
pkgopts=$@
cleanup=""

version=master
pfile=toast-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/toast/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="log_${pkg}"

echo "Building ${pkg}..." >&2

blas="-DBLAS_LIBRARIES=@AUX_PREFIX@/lib/libopenblas.a"
lapack="-DLAPACK_LIBRARIES=@AUX_PREFIX@/lib/libopenblas.a"
if [ "x@MKL@" != "x" ]; then
    blas="-DBLAS_LIBRARIES=@MKL@/lib/intel64/libmkl_rt.so"
    lapack="-DLAPACK_LIBRARIES=@MKL@/lib/intel64/libmkl_rt.so"
fi

rm -rf toast-${version}
tar xzf ${src} \
    && cd toast-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@MPICC@" \
    -DCMAKE_CXX_COMPILER="@MPICXX@" \
    -DMPI_C_COMPILER="@MPICC@" \
    -DMPI_CXX_COMPILER="@MPICXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -DFFTW_ROOT="@AUX_PREFIX@" ${blas} ${lapack} \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DSUITESPARSE_INCLUDE_DIR_HINTS="@AUX_PREFIX@/include" \
    -DSUITESPARSE_LIBRARY_DIR_HINTS="@AUX_PREFIX@/lib" \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    .. > "../../${log}" 2>&1 \
    && make -j @MAKEJ@ >> "../${log}" 2>&1 \
    && make install >> "../${log}" 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
