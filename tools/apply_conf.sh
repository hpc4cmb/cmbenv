#!/bin/bash

infile=$1
outfile=$2
conffile=$3
prefix=$4
version=$5
moddir=$6
docker=$7

# Script directory
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

compiled_prefix="${prefix}/cmbenv/${version}_aux"
python_prefix="${prefix}/cmbenv/${version}_python"
module_dir="${moddir}/cmbenv"

if [ "x${docker}" = "xyes" ]; then
    compiled_prefix="/usr"
    python_prefix="/usr"
fi

# Create list of substitutions

confsub="-e 's#@CONFFILE@#${conffile}#g'"

while IFS='' read -r line || [[ -n "${line}" ]]; do
    # is this line commented?
    comment=$(echo "${line}" | cut -c 1)
    if [ "${comment}" != "#" ]; then

        check=$(echo "${line}" | sed -e "s#.*=.*#=#")

        if [ "x${check}" = "x=" ]; then
            # get the variable and its value
            var=$(echo ${line} | sed -e "s#\([^=]*\)=.*#\1#" | awk '{print $1}')
            val=$(echo ${line} | sed -e "s#[^=]*= *\(.*\)#\1#")
            # add to list of substitutions
            confsub="${confsub} -e 's#@${var}@#${val}#g'"
        fi
    fi

done < "${conffile}"

# We add these predefined matches at the end- so that the config
# file can actually use these.

confsub="${confsub} -e 's#@AUX_PREFIX@#${compiled_prefix}#g'"
confsub="${confsub} -e 's#@PYTHON_PREFIX@#${python_prefix}#g'"
confsub="${confsub} -e 's#@VERSION@#${version}#g'"
confsub="${confsub} -e 's#@MODULE_DIR@#${module_dir}#g'"
confsub="${confsub} -e 's#@TOP_DIR@#${topdir}#g'"

rm -f "${outfile}"

while IFS='' read -r line || [[ -n "${line}" ]]; do
    echo "${line}" | eval sed ${confsub} >> "${outfile}"
done < "${infile}"
