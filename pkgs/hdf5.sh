#!/bin/bash

pkg="hdf5"
pkgopts=$@
cleanup=""

version=1.12.0

pfile=hdf5-${version}.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-${version}/src/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf hdf5-${version}
tar xjf ${src} \
    && cd hdf5-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@CFLAGS@"; \
       else echo "-O3"; fi) \
    CXX="@CXX@" CXXFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@CXXFLAGS@"; \
       else echo "-O3"; fi) \
    FC="@FC@" FCFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@FCFLAGS@"; \
       else echo "-O3"; fi) \
    ./configure \
    --enable-build-mode=production \
    --with-default-api-version=v110 \
    --disable-silent-rules \
    --disable-parallel \
    --enable-cxx \
    --disable-fortran \
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
