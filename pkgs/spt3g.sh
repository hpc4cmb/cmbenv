#!/bin/bash

pkg="spt3g"
pkgopts=$@
cleanup=""

# Manually git clone master
src="@TOP_DIR@/pool/spt3g_software"
if [ ! -d "${src}" ]; then
    git clone --branch master --single-branch --depth 1 https://github.com/CMB-S4/spt3g_software.git "${src}"
fi

if [ ! -d "${src}" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

echo "Building ${pkg}..." >&2

export spt3g_start=$(pwd)
log="${spt3g_start}/log_${pkg}"

rm -rf spt3g_software
cp -a "${src}" spt3g_software \
    && cd spt3g_software \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_spt3g" > ${log} 2>&1 \
    && cd .. \
    && rm -rf "@AUX_PREFIX@/spt3g" \
    && cp -a spt3g_software "@AUX_PREFIX@/spt3g" \
    && cd "@AUX_PREFIX@/spt3g" \
    && mkdir build \
    && cd build \
    && LDFLAGS="-Wl,-z,muldefs" \
    BOOST_ROOT="@AUX_PREFIX@" \
    cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DBOOST_ROOT="@AUX_PREFIX@" \
    -DPYTHON_EXECUTABLE:FILEPATH="@PYTHON_PREFIX@/bin/python" \
    .. >> ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && ln -s @AUX_PREFIX@/spt3g/build/bin/* @AUX_PREFIX@/bin/ \
    && ln -s @AUX_PREFIX@/spt3g/build/spt3g @AUX_PREFIX@/lib/python@PYVERSION@/site-packages/ \
    && cd ${spt3g_start}

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
