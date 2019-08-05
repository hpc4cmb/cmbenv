#!/bin/bash

url=$1
local=$2

# Top level cmbenv git checkout
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

# Pool directory
pooldir=""
if [ "x${CMBENV_POOL}" = "x" ]; then
    pooldir="${topdir}/pool"
else
    pooldir="${CMBENV_POOL}"
fi
mkdir -p "${pooldir}"

plocal="${pooldir}/${local}"

if [ ! -e "${plocal}" ]; then
    echo "Fetching ${local} to download pool..." >&2
    curl -SL "${url}" -o "${plocal}"
else
    echo "Found existing ${local} in download pool." >&2
fi

# Did we get the file?
if [ -e "${plocal}" ]; then
    echo "${plocal}"
    exit 0
else
    echo "FAIL"
    exit 1
fi
