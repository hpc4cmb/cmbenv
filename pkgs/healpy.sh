#!/bin/bash

pkg="healpy"
pkgopts=$@
cleanup=""

version=1.14.0
pfile=healpy-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/52/bb/21e57f6b3a4c2a3bb59fb2a284fccf6ea15241a180e86ace1f9b891e251b/${pfile} ${pfile})

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
    cat "${log}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
