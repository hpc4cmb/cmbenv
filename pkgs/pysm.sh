#!/bin/bash

pkg="pysm"
pkgopts=$@
cleanup=""

pfile=PySM_public-2.1.0.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/bthorne93/PySM_public/archive/2.1.0.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf PySM_public-2.1.0
tar xzf ${src} \
    && cd PySM_public-2.1.0 \
    && python setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
