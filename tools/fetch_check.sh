#!/bin/bash

url=$1
local=$2

# Top level cmbenv git checkout
pushd $(dirname $0) > /dev/null
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

# Pool directory
pooldir="${topdir}/pool"
mkdir -p "${pooldir}"

plocal="${pooldir}/${local}"

if [ ! -e "${plocal}" ]; then
    curl -SL "${url}" -o "${plocal}"
fi

# Did we get the file?
if [ -e "${plocal}" ]; then
    echo "${plocal}"
    exit 0
else
    echo "FAIL"
    exit 1
fi
