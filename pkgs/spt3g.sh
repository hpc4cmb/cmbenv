#!/bin/bash

pkg="spt3g"
pkgopts=$@
cleanup=""

version=master
pfile=spt3g_software-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/CMB-S4/spt3g_software/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

echo "Building ${pkg}..." >&2

export spt3g_start=$(pwd)
log="${spt3g_start}/log_${pkg}"

# Find the path to the python headers and libs, since cmake can't
export PYROOT=$(python-config --prefix)
export PYINC=$(python-config --includes | awk '{print $1}' | sed -e "s#-I##")
export PYLIB=${PYROOT}/lib/$(python-config --libs | awk '{print $1}' | sed -e "s#-l#lib#").so

# These environment variables are needed for cmake macros.
export BOOST_ROOT="${PYPREFIX}"
export BOOST_INCLUDEDIR="${PYPREFIX}/include"
export BOOST_LIBRARYDIR="${PYPREFIX}/lib"

rm -rf spt3g_software-${version}
tar xzf ${src} \
    && cd spt3g_software-${version} \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_spt3g" > ${log} 2>&1 \
    && cd .. \
    && rm -rf "@AUX_PREFIX@/spt3g" \
    && cp -a spt3g_software-${version} "@AUX_PREFIX@/spt3g" \
    && cd "@AUX_PREFIX@/spt3g" \
    && mkdir build \
    && cd build \
    && LDFLAGS="-Wl,-z,muldefs" \
    cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DFLAC_LIBRARIES="@AUX_PREFIX@/lib/libFLAC.so" \
    -DFLAC_INCLUDE_DIR="@AUX_PREFIX@/include" \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -DPYTHON_INCLUDE_DIR="${PYINC}" \
    -DPYTHON_LIBRARY="${PYLIB}" \
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
