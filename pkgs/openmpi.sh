#!/bin/bash

pkg="openmpi"
pkgopts=$@
cleanup=""

version=4.1.2
pdir=openmpi-${version}
pfile=${pdir}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://download.open-mpi.org/release/open-mpi/v4.1/${pfile} ${pfile})

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

echo "Building ${pkg}..." >&2

rm -rf ${pdir}

fcopt="--enable-mpi-fortran=usempi"
if [ "x@FC@" = "x" ]; then
    fcopt="--enable-mpi-fortran=no"
fi
unset F90
unset F90FLAGS

wrap=""
if [ "x@MPI_EXTRA_COMP@" != "x" ]; then
    wrap="${wrap} --with-wrapper-cflags=\"@MPI_EXTRA_COMP@\" --with-wrapper-cxxflags=\"@MPI_EXTRA_COMP@\" --with-wrapper-fcflags=\"@MPI_EXTRA_COMP@\""
fi

if [ "x@MPI_EXTRA_LINK@" != "x" ]; then
    wrap="${wrap} --with-wrapper-ldflags=\"@MPI_EXTRA_LINK@\""
fi

tar xzf ${src} \
    && cd ${pdir} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CXX="@CXX@" FC="@FC@" F77="@FC@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" \
    FFLAGS="@FCFLAGS@" FCFLAGS="@FCFLAGS@" \
    ./configure @CROSS@ ${fcopt} ${wrap} \
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
