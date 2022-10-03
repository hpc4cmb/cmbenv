#!/bin/bash

pkg="scipy"
pkgopts=$@
cleanup=""

version=1.9.1
pfile=scipy-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/db/af/16906139f52bc6866c43401869ce247662739ad71afa11c6f18505eb0546/${pfile} ${pfile})

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

rm -rf scipy-${version}
tar xzf ${src} \
    && cd scipy-${version} \
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
