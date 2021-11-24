#!/bin/bash

pkg="mpich"
pkgopts=$@
cleanup=""

version=3.2
pfile=mpich-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://www.mpich.org/static/downloads/${version}/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log="/dev/stdout"
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf mpich-${version}

fcopt="--enable-fortran"
if [ "x@FC@" = "x" ]; then
    fcopt="--disable-fortran"
fi
tar xzf ${src} \
    && cd mpich-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CXX="@CXX@" FC="@FC@" F77="@FC@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" \
    FFLAGS="@FCFLAGS@ -fallow-argument-mismatch" FCFLAGS="@FCFLAGS@" \
    ./configure @CROSS@ ${fcopt} \
    --with-device=ch3 \
    --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
