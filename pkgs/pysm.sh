#!/bin/bash

pkg="pysm"
pkgopts=$@
cleanup=""

version=3.2.0
pfile=pysm3-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/60/b3/daf8e62af528d8d749673069d9eee6006d6c9f9206531b80f3e6145b801d/pysm3-3.2.0.tar.gz  ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf pysm-${version}
tar xzf ${src} \
    && cd pysm3-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && python3 setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
