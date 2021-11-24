#!/bin/bash

pkg="gmp"
pkgopts=$@
cleanup=""

version=6.2.0
pdir=gmp-${version}
pfile=${pdir}.tar.xz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://ftp.gnu.org/gnu/gmp/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log = "/dev/stdout"
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf ${pdir}
tar xf ${src} \
    && cd ${pdir} \
    && cleanup="${cleanup} $(pwd)" \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    ./configure \
    --enable-static \
    --disable-shared \
    --with-pic \
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
