#!/bin/bash

# The current cmbenv version
version=$1

# The install prefix
prefix=$2

# The python prefix
python_prefix=$3

# The aux prefix
aux_prefix=$4

# The python version
pyversion=$5

# The python type
pytype=$6

# Conda type
condatype=$7

# Top level cmbenv git checkout
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

# The outputs
outfile="${python_prefix}/bin/cmbenv"
rm -f "${outfile}"

# Create list of variable substitutions to apply

confsub="-e 's#@PREFIX@#${prefix}#g'"
confsub="${confsub} -e 's#@VERSION@#${version}#g'"
confsub="${confsub} -e 's#@AUX_PREFIX@#${aux_prefix}#g'"
confsub="${confsub} -e 's#@PYTHON_PREFIX@#${python_prefix}#g'"
confsub="${confsub} -e 's#@PYVERSION@#${pyversion}#g'"
confsub="${confsub} -e 's#@PYTYPE@#${pytype}#g'"
confsub="${confsub} -e 's#@CONDATYPE@#${condatype}#g'"

# Process the template

while IFS='' read -r line || [[ -n "${line}" ]]; do
    echo "${line}" | eval sed ${confsub} >> "${outfile}"
done < "${topdir}/templates/cmbenv.in"
