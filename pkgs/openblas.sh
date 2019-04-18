#!/bin/bash

pkg="openblas"
pkgopts=$@
cleanup=""

pfile=v0.3.5.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/xianyi/OpenBLAS/archive/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf OpenBLAS-0.3.5
tar xzf ${src} \
    && cd OpenBLAS-0.3.5 \
    && make USE_OPENMP=1 NO_SHARED=1 \
    FC="@FC@" FFLAGS="@FCFLAGS@" \
    MAKE_NB_JOBS="@MAKEJ@" \
    CC="@CC@" CFLAGS="@CFLAGS@" > ${log} 2>&1 \
    && make NO_SHARED=1 PREFIX="@AUX_PREFIX@" install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
