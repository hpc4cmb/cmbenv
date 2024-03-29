#!/bin/bash

pkg="spt3g"
pkgopts=$@
cleanup=""

version=4da2f4b5b6cba198803a2efbffc8892d220b7e63
pfile=spt3g_software-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/CMB-S4/spt3g_software/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

echo "Building ${pkg}..." >&2

export spt3g_start=$(pwd)

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stderr
else
    log="${spt3g_start}/log_${pkg}"
fi

boost="@AUX_PREFIX@"
flaclib="@AUX_PREFIX@/lib/libFLAC.so"
flacinc="@AUX_PREFIX@/include"
for opt in $pkgopts; do
    chkboost=$(echo $opt | sed -e "s/boost=\(.*\)/\1/")
    if [ "x$chkboost" != "x$opt" ]; then
        boost="${chkboost}"
    fi
    chkflac=$(echo $opt | sed -e "s/flaclib=\(.*\)/\1/")
    if [ "x$chkflac" != "x$opt" ]; then
        flaclib="${chkflac}"
        flacinc="$(dirname ${flaclib})/../include"
    fi
done

# Short version of python to use
pyshort=$(echo @PYVERSION@ | sed -e "s/\.//")

# The spt3g package uses Cereal and Boost, which have issues building with some vendor
# compilers (e.g. Intel).  Instead, we use the OS compilers (typically gcc or clang)
# for compilation.

rm -rf spt3g_software-${version}
tar xzf ${src} \
    && cd spt3g_software-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir build \
    && cd build \
    && LDFLAGS="-Wl,-z,muldefs" \
    cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="@BUILD_CC@" \
    -DCMAKE_CXX_COMPILER="@BUILD_CXX@" \
    -DCMAKE_C_FLAGS="-O3 -fPIC" \
    -DCMAKE_CXX_FLAGS="-O3 -fPIC -std=c++11" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DBOOST_ROOT="${boost}" \
    -DBoost_PYTHON_TYPE="python${pyshort}" \
    -DBoost_ARCHITECTURE=-x64 \
    -DBoost_DEBUG=ON \
    -DFLAC_LIBRARIES="${flaclib}" \
    -DFLAC_INCLUDE_DIR="${flacinc}" \
    -DPython_USE_STATIC_LIBS=FALSE \
    -DPython_EXECUTABLE:FILEPATH=$(which python3) \
    -DPYTHON_MODULE_DIR="@AUX_PREFIX@/lib/python@PYVERSION@/site-packages" \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    .. >> ${log} 2>&1 \
    && make -j @MAKEJ@ install >> ${log} 2>&1 \
    && cd ${spt3g_start}

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
