#!/bin/bash

pkg="pysm"
pkgopts=$@
cleanup=""

version=3.3.2
pfile=pysm3-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/8a/10/cecd80d1f14b8ebcb3c85bc9478d9774574f82305d316446e84da7221394/${pfile} ${pfile})

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

rm -rf pysm-${version}
tar xzf ${src} \
    && cd pysm3-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && python3 -m pip install --prefix="@AUX_PREFIX@" . > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
