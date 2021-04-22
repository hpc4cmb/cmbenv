#!/bin/bash

pkg="toast"
pkgopts=$@
cleanup=""

version=2.3.12
pfile=toast-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/toast/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../../log_${pkg}"

echo "Building ${pkg}..." >&2

# Parse options for dependency install prefix
fftw=""
ssparse=""
blas=""
lapack=""

if [ "x@MKL@" != "x" ]; then
    blas="@MKL@/lib/intel64/libmkl_rt.so"
    lapack="@MKL@/lib/intel64/libmkl_rt.so"
fi

for opt in $pkgopts; do
    chkfftw=$(echo $opt | sed -e "s/fftw=\(.*\)/\1/")
    if [ "x$chkfftw" != "x$opt" ]; then
        fftw="${chkfftw}"
    fi
    chksparse=$(echo $opt | sed -e "s/suitesparse=\(.*\)/\1/")
    if [ "x$chksparse" != "x$opt" ]; then
        ssparse="${chksparse}"
    fi
    chkblas=$(echo $opt | sed -e "s/blas=\(.*\)/\1/")
    if [ "x$chkblas" != "x$opt" ]; then
        blas="${chkblas}"
    fi
    chklapack=$(echo $opt | sed -e "s/lapack=\(.*\)/\1/")
    if [ "x$chklapack" != "x$opt" ]; then
        lapack="${chklapack}"
    fi
done

fftw_root=""
if [ "x$fftw" != "x" ]; then
    fftw_root="-DFFTW_ROOT=$fftw"
fi

suitesparse=""
if [ "x$ssparse" != "x" ]; then
    suitesparse="-DSUITESPARSE_INCLUDE_DIR_HINTS=$ssparse/include -DSUITESPARSE_LIBRARY_DIR_HINTS=$ssparse/lib"
fi

blaslib=""
if [ "x$blas" != "x" ]; then
    blaslib="-DBLAS_LIBRARIES=${blas}"
fi

lapacklib=""
if [ "x$lapack" != "x" ]; then
    lapacklib="-DLAPACK_LIBRARIES=${lapack}"
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
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    ${fftw_root} ${suitesparse} ${blaslib} ${lapacklib} .. > "${log}" 2>&1 \
    && make -j @MAKEJ@ >> "${log}" 2>&1 \
    && make install >> "${log}" 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
