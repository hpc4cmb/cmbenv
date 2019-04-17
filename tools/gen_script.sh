#!/bin/bash

# This is (for example) install.in, Dockerfile.in, etc
template=$1

# The config file definitions and package list
conffile=$2
pkgfile=$3
confmodinit=$4

# The output root of the install script
outroot=$5

# Runtime options
prefix=$6
version=$7
moddir=$8

# Is this template a dockerfile?  If this is "yes", then when calling
# package scripts we will insert the "RUN " prefix and also capture the
# downloaded files so that we can clean them up on the same line without
# polluting the image.
docker=$9


# Top level cmbenv git checkout
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

# The outputs
if [ "x${docker}" = "xyes" ]; then
    outfile="${outroot}"
else
    outfile="${outroot}.sh"
fi
outmod="${outroot}.mod"
outmodver="${outroot}.modver"
outpkg="${outroot}_pkgs"
rm -f "${outfile}"
rm -f "${outmod}"
rm -f "${outmodver}"
rm -rf "${outpkg}"

mkdir -p "${outpkg}"


# Create list of variable substitutions from the input config file

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
# file can actually use these as well.

compiled_prefix="${prefix}/cmbenv/${version}_aux"
python_prefix="${prefix}/cmbenv/${version}_python"
module_dir="${moddir}/cmbenv"

if [ "x${docker}" = "xyes" ]; then
    compiled_prefix="/usr"
    python_prefix="/usr"
fi

confsub="${confsub} -e 's#@AUX_PREFIX@#${compiled_prefix}#g'"
confsub="${confsub} -e 's#@PYTHON_PREFIX@#${python_prefix}#g'"
confsub="${confsub} -e 's#@VERSION@#${version}#g'"
confsub="${confsub} -e 's#@MODULE_DIR@#${module_dir}#g'"
confsub="${confsub} -e 's#@TOP_DIR@#${topdir}#g'"


# Process each selected package for this config.  Copy each package file into
# the output location while substituting config variables.  Also build up the
# text that will be inserted into the template.

pkgcom=""

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^#.* ]]; then
        # This is a comment line
    else
        # This is a package line
        pkgname=""
        pkgopts=""
        if [[ "${line}" =~ ":" ]]; then
            # We have a package and options
            pkgname=$(echo "${line}" | sed -e 's/\(.*\):.*/\1/')
            pkgopts=$(echo "${line}" | sed -e 's/.*:\(.*\)/\1/')
        else
            # We have just a package
            pkgname=$(echo "${line}" | awk -e '{print $1}')
        fi

        # Copy the package file into place while applying the config.
        while IFS='' read -r pkgline || [[ -n "${pkgline}" ]]; do
            echo "${pkgline}" | eval sed ${confsub} >> "${topdir}/${outpkg}/${pkgname}.sh"
        done < "${topdir}/pkgs/${pkgname}.sh"

        # Copy any patch file
        if [ -e "${topdir}/pkgs/patch_${pkgname}" ]; then
            cp -a "${topdir}/pkgs/patch_${pkgname}" "${topdir}/${outpkg}/"
        fi

        if [ "x${docker}" = "xyes" ]; then
            pkgcom="${pkgcom}RUN cln=\$(./${outpkg}/${pkgname}.sh) && for cl in \${cln}; do if [ -e \${cl} ]; rm \"\${cl}\"; fi; done\n"
        else
            pkgcom="${pkgcom}cln=\$(./${outpkg}/${pkgname}.sh); if [ $? -ne 0 ]; then echo \"FAILED\"; exit 1; fi\n"
        fi
    fi
done < "${pkgfile}"


# Now process the input template, substituting the list of package install
# commands that we just built.

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ @PACKAGES@ ]]; then
        echo "${pkgcom}" >> "${outfile}"
    else
        echo "${line}" >> "${outfile}"
    fi
done < "${topdir}/templates/${template}"


# Finally, create the module file and module version file for this config.

if [ "x${docker}" != "xyes" ]; then
    while IFS='' read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" =~ @modload@ ]]; then
            if [ -e "${confmodinit}" ]; then
                cat "${confmodinit}" >> "${outmod}"
            fi
        else
            echo "${line}" >> "${outmod}"
        fi
    done < "${topdir}/templates/modulefile.in"

    while IFS='' read -r line || [[ -n "${line}" ]]; do
        echo "${line}" | eval sed ${confsub} >> "${outmodver}"
    done < "${topdir}/templates/version.in"
fi
