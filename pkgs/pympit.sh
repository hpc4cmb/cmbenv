#!/bin/bash

pkg="pympit"
pkgopts=$@
cleanup=""

version=0.1.0
pfile=pympit-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/tskisner/pympit/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf pympit-${version}
tar xzf ${src} \
    && cd pympit-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && python3 -m pip install --prefix="@AUX_PREFIX@" . > ${log} 2>&1 \
    && cd compiled \
    && CC="@MPICC@" make >> ${log} 2>&1 \
    && cp pympit_compiled "@AUX_PREFIX@/bin/"

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
