#!/bin/bash

pkg="pixell"
version=0.12.0
psrc=${pkg}-${version}
pfile=${psrc}.tar.gz

fetched=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/simonsobs/pixell/archive/v${version}.tar.gz ${pfile})

if [ "x${fetched}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stdout
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf ${psrc}
tar xzf ${fetched} \
    && cd ${psrc} \
    && python3 -m pip install --prefix="@AUX_PREFIX@" . >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
exit 0
