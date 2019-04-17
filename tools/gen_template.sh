#!/bin/bash

template=$1
pkgfile=$2
outfile=$3
precommand=$4

# Script directory
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

outpkg="${outfile}_pkgs"
rm -f "${outfile}"
rm -rf "${outfile}_pkgs"

mkdir -p "${outpkg}"



while IFS='' read -r line || [[ -n "${line}" ]]; do
    match="no"
    for rule in ${rules}; do
        rulefile="rules/${rule}.sh"
        if [[ "${line}" =~ @${rule}@ ]]; then
            match="yes"
            echo -n "${precommand} " >> "${outfile}"
            cat "${rulefile}" >> "${outfile}"
            break
        fi
    done
    if [ "${match}" = "no" ]; then
        echo "${line}" >> "${outfile}"
    fi
done < "${infile}"
