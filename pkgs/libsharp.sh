#!/bin/bash

pkg="libsharp"
pkgopts=$@
cleanup=""

version=1.0.0
pfile=libsharp-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/Libsharp/libsharp/archive/v${version}.tar.gz ${pfile})

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

rm -rf libsharp-${version}
tar xzf ${src} \
    && cd libsharp-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_libsharp" > ${log} 2>&1 \
    && autoreconf >> ${log} 2>&1 \
    && CC="@MPICC@" CFLAGS="@CFLAGS@ -std=c99" \
    ./configure @CROSS@ --enable-mpi --enable-pic \
    --prefix="@AUX_PREFIX@" >> ${log} 2>&1 \
    && make >> ${log} 2>&1 \
    && cp -a auto/* "@AUX_PREFIX@/" \
    && cd python \
    && LIBSHARP="@AUX_PREFIX@" CC="@MPICC@ -g" LDSHARED="@MPICC@ -g -shared" \
    python3 -m pip install --prefix="@AUX_PREFIX@" . >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
