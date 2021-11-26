#!/bin/bash

pkg="hdf5"
pkgopts=$@
cleanup=""

version=1.12.1

pfile=hdf5-${version}.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-${version}/src/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stdout
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf hdf5-${version}
tar xjf ${src} \
    && cd hdf5-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@MPICC@" CFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@CFLAGS@"; \
       else echo "-O3"; fi) \
    CXX="@MPICXX@" CXXFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@CXXFLAGS@"; \
       else echo "-O3"; fi) \
    FC="@MPIFC@" FCFLAGS=$(if [ "x@CROSS@" = x ]; then echo "@FCFLAGS@"; \
       else echo "-O3"; fi) \
    ./configure \
    --enable-build-mode=production \
    --disable-silent-rules \
    --enable-parallel \
    --enable-fortran \
    --enable-shared \
    --disable-static \
    --with-pic \
    --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

# Should not be needed with latest h5py...
# --with-default-api-version=v110 \

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
