#!/bin/bash

pkg="healpy"
pkgopts=$@
cleanup=""

version=1.15.0
pfile=healpy-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/72/43/b0b2d086de23157f0a478b22252cf68e184aeb7632a2ddef861b5b83e3b1/${pfile} ${pfile})

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

rm -rf healpy-${version}
tar xzf ${src} \
    && cd healpy-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CXX="@CXX@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" \
    python3 -m pip install --prefix="@AUX_PREFIX@" . > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
