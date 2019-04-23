#!/bin/bash

pkg="madam"
pkgopts=$@
cleanup=""

if [ "x@MPIFC@" = "x" ]; then
    echo "Skipping package ${pkg}, which requires a Fortran compiler" >&2
    exit 0
fi

pfile=libmadam-1.0.1.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/libmadam/releases/download/v1.0.1/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf libmadam-1.0.1
tar xjf ${src} \
    && cd libmadam-1.0.1 \
    && FC="@MPIFC@" MPIFC="@MPIFC@" FCFLAGS="@FCFLAGS@" \
    CC="@MPICC@" MPICC="@MPICC@" CFLAGS="@CFLAGS@" \
    ./configure @CROSS@ --with-cfitsio="@AUX_PREFIX@" \
    --with-blas="@BLAS@" --with-lapack="@LAPACK@" \
    --with-fftw="@AUX_PREFIX@" --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
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