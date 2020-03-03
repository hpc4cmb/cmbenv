#!/bin/bash

pkg="spt3g"
pkgopts=$@
cleanup=""

version=ce2dd75675229475286d9867b70eac57bbcdd7f5
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

rm -rf spt3g_software-${version}
tar xzf ${src} \
    && cd spt3g_software-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_spt3g" > ${log} 2>&1 \
    && cd .. \
    && rm -rf "@AUX_PREFIX@/spt3g" \
    && cp -a spt3g_software-${version} "@AUX_PREFIX@/spt3g" \
    && cd "@AUX_PREFIX@/spt3g" \
    && mkdir build \
    && cd build \
    && LDFLAGS="-Wl,-z,muldefs" \
    cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DBOOST_ROOT="${boost}" \
    -DBoost_PYTHON_TYPE="python${pyshort}" \
    -DBoost_ARCHITECTURE=-x64 \
    -DFLAC_LIBRARIES="${flaclib}" \
    -DFLAC_INCLUDE_DIR="${flacinc}" \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
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
