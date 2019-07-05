#!/bin/bash

pkg="h5py"
pkgopts=$@
cleanup=""

pfile=h5py-2.9.0.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/43/27/a6e7dcb8ae20a4dbf3725321058923fec262b6f7835179d78ccc8d98deec/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf h5py-2.9.0
tar xzf ${src} \
    && cd h5py-2.9.0 \
    && python3 setup.py --hdf5="@AUX_PREFIX@" > ${log} \
    && CC="@CC@" python3 setup.py install --prefix "@AUX_PREFIX@" >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
