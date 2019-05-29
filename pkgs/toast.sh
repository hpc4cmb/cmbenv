#!/bin/bash

pkg="toast"
pkgopts=$@
cleanup=""

pfile=toast-2.2.8.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hpc4cmb/toast/archive/2.2.8.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

mklopt=""
if [ "x@MKL@" != "x" ]; then
    mklopt="--with-math=\"-limf -lsvml\" --with-mkl=\"@MKL@/lib/intel64\""
fi

rm -rf toast-2.2.8
tar xzf ${src} \
    && cd toast-2.2.8 \
    && ./autogen.sh \
    && PYTHON=python3 \
    CC="@MPICC@" \
    CXX="@MPICXX@" \
    MPICC="@MPICC@" \
    MPICXX="@MPICXX@" \
    CFLAGS="@CFLAGS@" \
    CXXFLAGS="@CXXFLAGS@" \
    ./configure ${mklopt} \
    --prefix="@AUX_PREFIX@" \
    > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
