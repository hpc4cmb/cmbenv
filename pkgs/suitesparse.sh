#!/bin/bash

pkg="suitesparse"
pkgopts=$@
cleanup=""

version=5.4.0
pfile=SuiteSparse-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://faculty.cse.tamu.edu/davis/SuiteSparse/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf SuiteSparse
tar xzf ${src} \
    && cd SuiteSparse \
    && cleanup="${cleanup} $(pwd)" \
    && make library JOBS=@MAKEJ@ \
    CC="@CC@" CXX="@CXX@" CFLAGS="@CFLAGS@" AUTOCC=no \
    GPU_CONFIG="" \
    CFOPENMP="@OPENMP_CXXFLAGS@" LAPACK="@LAPACK@" BLAS="@BLAS@" \
    > ${log} 2>&1 \
    && cp -a ./lib/* "@AUX_PREFIX@/lib/" \
    && cp -a ./include/* "@AUX_PREFIX@/include/" \
    && find . -name "*.a" -exec cp -a '{}' "@AUX_PREFIX@/lib/" \;

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
