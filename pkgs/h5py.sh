#!/bin/bash

pkg="h5py"
pkgopts=$@
cleanup=""

hdf5pref='HDF5_DIR="@AUX_PREFIX@"'
if [ "x$pkgopts" != "x" ]; then
    if [ "x$pkgopts" = "xpkg-config" ]; then
        hdf5pref=""
    else
        hdf5pref="$pkgopts"
    fi
fi

# Note- the download URL includes a checksum and will need to
# be updated when you change this version string.
version=3.5.0

pfile=h5py-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/h5py/h5py/archive/refs/tags/${version}.tar.gz ${pfile})

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

rm -rf h5py-${version}
tar xzf ${src} \
    && cd h5py-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@MPICC@" HDF5_MPI="ON" ${hdf5pref} pip install -v --prefix "@AUX_PREFIX@" . >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
