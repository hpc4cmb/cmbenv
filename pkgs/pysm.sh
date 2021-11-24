#!/bin/bash

pkg="pysm"
pkgopts=$@
cleanup=""

version=3.3.0
pfile=pysm3-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/0a/bd/8a3d2306f3ab1ce06f3bf22139875ad01e7c9671286baebd016cd9662fa7/pysm3-3.3.0.tar.gz ${pfile})

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
