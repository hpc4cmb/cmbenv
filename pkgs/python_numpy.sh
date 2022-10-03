#!/bin/bash

pkg="numpy"
pkgopts=$@
cleanup=""

version=1.23.3
pfile=numpy-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/0a/88/f4f0c7a982efdf7bf22f283acf6009b29a9cc5835b684a49f8d3a4adb22f/${pfile} ${pfile})

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

rm -rf numpy-${version}
tar xzf ${src} \
    && cd numpy-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && OPT="-O3 -fPIC -DNDEBUG" FOPT="-O3 -fPIC -DNDEBUG" \
    CC="@BUILD_CC@" CXX="@BUILD_CXX@" FC="@BUILD_FC@" \
    CFLAGS="-O3 -fPIC -DNDEBUG" FCFLAGS="-O3 -fPIC -DNDEBUG" \
    LDSHARED="@BUILD_CC@ -shared" \
    NPY_BLAS_LIBS="@LAPACK@ @BLAS@" \
    NPY_CBLAS_LIBS="@LAPACK@ @BLAS@" \
    python3 -m pip -vvv install --prefix "@AUX_PREFIX@" . > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
