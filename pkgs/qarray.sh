#!/bin/bash

pkg="qarray"
pkgopts=$@
cleanup=""

pfile=quaternionarray-0.6.2.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/27/1b/4f2bcfd1bf3d78173cf2c05d79b3c129ed789e99e072c220bf5041b31076/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf quaternionarray-0.6.2
tar xzf ${src} \
    && cd quaternionarray-0.6.2 \
    && python setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
