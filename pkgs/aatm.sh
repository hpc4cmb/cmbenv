#!/bin/bash

pkg="aatm"
pkgopts=$@
cleanup=""

pfile=aatm-0.5.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://launchpad.net/aatm/trunk/0.5/+download/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf aatm-0.5
tar xzf ${src} \
    && cd aatm-0.5 \
    && chmod -R u+w . \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_aatm" > ${log} 2>&1 \
    && autoreconf >> ${log} 2>&1 \
    && CC="@CC@" CFLAGS="@CFLAGS@" \
    CPPFLAGS="-I@AUX_PREFIX@/include" \
    LDFLAGS="-L@AUX_PREFIX@/lib" \
    ./configure @CROSS@ \
    --prefix="@AUX_PREFIX@" >> ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
