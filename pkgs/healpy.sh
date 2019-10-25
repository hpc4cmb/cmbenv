#!/bin/bash

pkg="healpy"
pkgopts=$@
cleanup=""

version=1.12.10
pfile=healpy-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/e6/34/da61364cd7826ae6da0dd5cdc0ac1abaa933bf6bee4381986f326bc87a23/healpy-1.12.10.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf healpy-${version}
tar xzf ${src} \
    && cd healpy-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CXX="@CXX@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" \
    python3 setup.py install --prefix "@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
