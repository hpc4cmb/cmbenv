#!/bin/bash

pkg="boost"
pkgopts=$@
cleanup=""

# NOTE:  change URL when changing version.
version=1_76_0

pfile=boost_${version}.tar.bz2
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/${pfile} ${pfile})

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

# NOTE:  Due to perpetual flakiness of boost compilation with vendor compilers
# (e.g. Intel), we build boost with separate OS compilers (usually gcc or clang),
# as specified by the config BOOSTCHAIN variable.

rm -rf boost_${version}
tar xjf ${src} \
    && cd boost_${version} \
    && cleanup="${cleanup} $(pwd)" \
    && echo "option jobs : @MAKEJ@ ;" >> tools/build/user-config.jam \
    && BOOST_BUILD_USER_CONFIG=tools/build/user-config.jam \
    BZIP2_INCLUDE="@AUX_PREFIX@/include" \
    BZIP2_LIBPATH="@AUX_PREFIX@/lib" \
    ./bootstrap.sh \
    --with-toolset=@BOOSTCHAIN@ \
    --with-python=python3 \
    --prefix=@AUX_PREFIX@ > ${log} 2>&1 \
    && ./b2 --layout=tagged --user-config=./tools/build/user-config.jam \
    $(python3-config --includes | sed -e 's/-I//g' -e 's/\([^[:space:]]\+\)/ include=\1/g') \
    variant=release threading=multi link=shared runtime-link=shared install \
    >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
