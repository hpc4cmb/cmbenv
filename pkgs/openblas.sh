#!/bin/bash

pkg="openblas"
pkgopts=$@
cleanup=""

version=0.3.21
pfile=OpenBLAS-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/xianyi/OpenBLAS/archive/v${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stderr
else
    log="../log_${pkg}"
fi

static="no"
for opt in $pkgopts; do
    chkstatic=$(echo $opt | sed -e "s/static=\(.*\)/\1/")
    if [ "x$chkstatic" != "x$opt" ]; then
        static="${chkstatic}"
    fi
done

echo "Building ${pkg}..." >&2

rm -rf OpenBLAS-${version}
tar xzf ${src} \
    && cd OpenBLAS-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_openblas" > ${log} 2>&1 \
    && if [ "$static" = "yes" ]; then
    make NO_SHARED=1 USE_OPENMP=1 \
    FC="@FC@" \
    MAKE_NB_JOBS="@MAKEJ@" \
    CC="@CC@" DYNAMIC_ARCH=1 TARGET=GENERIC \
    CROSS=$(if [ "x@CROSS@" = x ]; then echo "0"; else echo "1"; fi) \
    COMMON_OPT="@CFLAGS@" \
    FCOMMON_OPT="@FCFLAGS@" \
    LDFLAGS="@OPENMP_CFLAGS@ -lm" >> ${log} 2>&1 \
    && make NO_SHARED=1 PREFIX="@AUX_PREFIX@" install >> ${log} 2>&1; \
    else make USE_OPENMP=1 \
    FC="@FC@" \
    MAKE_NB_JOBS="@MAKEJ@" \
    CC="@CC@" DYNAMIC_ARCH=1 TARGET=GENERIC \
    CROSS=$(if [ "x@CROSS@" = x ]; then echo "0"; else echo "1"; fi) \
    COMMON_OPT="@CFLAGS@" \
    FCOMMON_OPT="@FCFLAGS@" \
    LDFLAGS="@OPENMP_CFLAGS@ -lm" > ${log} 2>&1 \
    && make PREFIX="@AUX_PREFIX@" install >> ${log} 2>&1; fi

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
