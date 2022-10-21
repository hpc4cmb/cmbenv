#!/bin/bash

pkg="pyfftw"
pkgopts=$@
cleanup=""

version=0.13.0
pfile=pyFFTW-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/18/a1/5eb99c183af0a49bf632fed3260a6cad3f7978bb19fd661a573d3728a986/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stderr
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf pyFFTW-${version}
tar xzf ${src} \
    && cd pyFFTW-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && CFLAGS="@CFLAGS@" LDFLAGS="@LDFLAGS@" \
    PYFFTW_INCLUDE="@AUX_PREFIX@/include" \
    PYFFTW_LIB_DIR="@AUX_PREFIX@/lib" \
    python3 -m pip install --prefix="@AUX_PREFIX@" . > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
