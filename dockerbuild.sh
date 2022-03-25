#!/bin/bash

show_help () {
    echo "" >&2
    echo "Usage:  $0 <docker file>" >&2
    echo "" >&2
    echo "    Helper script to run docker build on a generated dockerfile" >&2
    echo "" >&2
    echo "    You should first run \"./cmbenv -c <docker config>\" to generate" >&2
    echo "    The dockerfile.  Then use this script to build it.  A copy of the" >&2
    echo "    build output is logged to the 'logs' directory." >&2
    echo "" >&2
    echo "" >&2
}

dockerfile=$1

if [ "x${dockerfile}" = "x" ]; then
    show_help
    exit 1
fi

# Get the absolute path to the directory with this script
pushd $(dirname $0) > /dev/null
topdir=$(pwd -P)
popd > /dev/null

# We must run from this directory...
curdir=$(pwd -P)
if [ "${curdir}" != "${topdir}" ]; then
    echo "You must run this script from cmbenv source directory."
    exit 1
fi

mkdir -p "${topdir}/logs"
logfile="${topdir}/logs/$(basename ${dockerfile}).log"

com="docker build -f \"${dockerfile}\" . 2>&1 | tee \"${logfile}\""
echo ${com}
eval ${com}

exit 0
