#!/bin/bash

pkg="suitesparse"
pkgopts=$@
cleanup=""

version=5.10.1
pfile=SuiteSparse-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

gpuconf=""
static="no"
for opt in $pkgopts; do
    chkgpu=$(echo $opt | sed -e "s/gpu=\(.*\)/\1/")
    if [ "x$chkgpu" != "x$opt" ]; then
        gpuconf="${chkgpu}"
    fi
    chkstatic=$(echo $opt | sed -e "s/static=\(.*\)/\1/")
    if [ "x$chkstatic" != "x$opt" ]; then
        static="${chkstatic}"
    fi
done

echo "Building ${pkg}..." >&2

rm -rf SuiteSparse-${version}
tar xzf ${src} \
    && cd SuiteSparse-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_suitesparse" > ${log} 2>&1 \
    && make library JOBS=@MAKEJ@ \
    CC="@CC@" CXX="@CXX@" CFLAGS="@CFLAGS@" AUTOCC=no \
    GPU_CONFIG="${gpuconf}" \
    CFOPENMP="@OPENMP_CXXFLAGS@" LAPACK="@LAPACK@" BLAS="@BLAS@" \
    > ${log} 2>&1 \
    && if [ "$static" = "yes" ]; then make static JOBS=@MAKEJ@ \
    CC="@CC@" CXX="@CXX@" CFLAGS="@CFLAGS@" AUTOCC=no \
    GPU_CONFIG="${gpuconf}" \
    CFOPENMP="@OPENMP_CXXFLAGS@" LAPACK="@LAPACK@" BLAS="@BLAS@" \
    > ${log} 2>&1; fi \
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
