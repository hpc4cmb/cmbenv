#!/bin/bash

pkg="fitsio"
pkgopts=$@
cleanup=""

version=1.0.1
pfile=fitsio-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/esheldon/fitsio/archive/v${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf fitsio-${version}
tar xzf ${src} \
    && cd fitsio-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && python3 -m pip install --prefix="@AUX_PREFIX@" . > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
