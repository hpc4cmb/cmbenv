#!/bin/bash

pkg="pysm"
pkgopts=$@
cleanup=""

# Clone git master for now
src="@TOP_DIR@/pool/pysm"
if [ ! -d "${src}" ]; then
    git clone --branch master --single-branch --depth 1 https://github.com/healpy/pysm.git "${src}"
fi

if [ ! -d "${src}" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf pysm
cp -a "${src}" pysm \
    && cd pysm \
    && python3 setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
