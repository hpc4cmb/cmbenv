#!/bin/bash

pkg="mpfr"
pkgopts=$@
cleanup=""

version=4.1.0
pdir=mpfr-${version}
pfile=${pdir}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" http://ftpmirror.gnu.org/mpfr/${pfile} ${pfile})

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

rm -rf ${pdir}
tar xzf ${src} \
    && cd ${pdir} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    ./configure \
    --enable-static \
    --disable-shared \
    --with-pic \
    --with-gmp="@AUX_PREFIX@" \
    --prefix="@AUX_PREFIX@" > ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
