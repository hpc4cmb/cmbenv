#!/bin/bash

pkg="fitsio"
pkgopts=$@
cleanup=""

version=1.1.7
pfile=fitsio-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/7a/bd/e29443e44bf67300daf87df40246d15290ea9f3a3cb4b07274b536e1c96a/${pfile} ${pfile})

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
