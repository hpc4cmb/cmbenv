#!/bin/bash

pkg="healpy"
pkgopts=$@
cleanup=""

pfile=healpy-1.12.9.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/healpy/healpy/releases/download/1.12.9/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf healpy-1.12.9
tar xzf ${src} \
    && cd healpy-1.12.9 \
    python setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
