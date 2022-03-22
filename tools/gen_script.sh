#!/bin/bash

# This is (for example) install.in, Dockerfile.in, etc
template=$1

# The config file definitions and package list
config=$2
conffile=$3
pkgfile=$4
confmodinit=$5
confshinit=$6

# The output root of the install script
outroot=$7

# Runtime options
prefix=$8
version=$9
moddir=${10}

# Is this template a dockerfile?  If this is "yes", then when calling
# package scripts we will insert the "RUN " prefix and also capture the
# downloaded files so that we can clean them up on the same line without
# polluting the image.
docker=${11}

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
outmod="${outfile}.mod"
outmodver="${outfile}.modver"
outinit="${outfile}.init"
outpkg="${outroot}_pkgs"
rm -f "${outfile}"
rm -f "${outmod}"
rm -f "${outmodver}"
rm -rf "${outpkg}"

mkdir -p "${outpkg}"

# Helper function to get the python version
get_pyversion () {
    ver=$(python3 --version 2>&1 | awk '{print $2}' | sed -e "s#\(.*\)\.\(.*\)\..*#\1.\2#")
    echo ${ver}
}

# Create list of variable substitutions from the input config file.  We add special
# handling for variables that *may* be defined, which are used by some packages.
# If the variables are not found, we set them to an empty string.

found_mkl="no"
mkl_val=""

found_cuda="no"
found_cuda_inc="no"
found_cuda_lib="no"
cuda_val=""
cuda_inc_val=""
cuda_lib_val=""

found_cudamath="no"
found_cudamath_inc="no"
found_cudamath_lib="no"
cudamath_val=""
cudamath_inc_val=""
cudamath_lib_val=""

found_pyversion="no"
pyversion=""

found_cross="no"
cross_val=""

confsub="-e 's#@CONFFILE@#${conffile}#g'"
confsub="${confsub} -e 's#@CONFIG@#${config}#g'"

while IFS='' read -r line || [[ -n "${line}" ]]; do
    # is this line commented?
    comment=$(echo "${line}" | cut -c 1)
    if [ "${comment}" != "#" ]; then

        check=$(echo "${line}" | sed -e "s#.*=.*#=#")

        if [ "x${check}" = "x=" ]; then
            # get the variable and its value
            var=$(echo ${line} | sed -e "s#\([^=]*\)=.*#\1#" | awk '{print $1}')
            val=$(echo ${line} | sed -e "s#[^=]*= *\(.*\)#\1#")
            if [ "${var}" = "PYVERSION" ]; then
                if [ "x${val}" = "xauto" ]; then
                    val=$(get_pyversion)
                fi
                pyversion="${val}"
                found_pyversion="yes"
            elif [ "${var}" = "MKL" ]; then
                found_mkl="yes"
                mkl_val="${val}"
            elif [ "${var}" = "CROSS" ]; then
                found_cross="yes"
                cross_val="${val}"
            elif [ "${var}" = "CUDA" ]; then
                found_cuda="yes"
                cuda_val="${val}"
            elif [ "${var}" = "CUDA_INC" ]; then
                found_cuda_inc="yes"
                cuda_inc_val="${val}"
            elif [ "${var}" = "CUDA_LIB" ]; then
                found_cuda_lib="yes"
                cuda_lib_val="${val}"
            elif [ "${var}" = "CUDA_MATH" ]; then
                found_cudamath="yes"
                cudamath_val="${val}"
            elif [ "${var}" = "CUDA_MATH_INC" ]; then
                found_cudamath_inc="yes"
                cudamath_inc_val="${val}"
            elif [ "${var}" = "CUDA_MATH_LIB" ]; then
                found_cudamath_lib="yes"
                cudamath_lib_val="${val}"
            else
                # add to list of substitutions
                confsub="${confsub} -e 's#@${var}@#${val}#g'"
            fi
        fi
    fi
done < "${conffile}"

if [ "${found_pyversion}" = "no" ]; then
    pyversion=$(get_pyversion)
fi
confsub="${confsub} -e 's#@PYVERSION@#${pyversion}#g'"

confsub="${confsub} -e 's#@MKL@#${mkl_val}#g'"
confsub="${confsub} -e 's#@CROSS@#${cross_val}#g'"

if [ "${found_cuda}" = "no" ]; then
    confsub="${confsub} -e 's#@CUDA@##g'"
    confsub="${confsub} -e 's#@CUDA_INC@##g'"
    confsub="${confsub} -e 's#@CUDA_LIB@##g'"
    confsub="${confsub} -e 's#@CUDA_MATH@##g'"
    confsub="${confsub} -e 's#@CUDA_MATH_INC@##g'"
    confsub="${confsub} -e 's#@CUDA_MATH_LIB@##g'"
else
    confsub="${confsub} -e 's#@CUDA@#${cuda_val}#g'"
    if [ "${found_cuda_inc}" = "no" ]; then
        cuda_inc_val="${cuda_val}/include"
    fi
    confsub="${confsub} -e 's#@CUDA_INC@#${cuda_inc_val}#g'"
    if [ "${found_cuda_lib}" = "no" ]; then
        cuda_lib_val="${cuda_val}/lib64"
    fi
    confsub="${confsub} -e 's#@CUDA_LIB@#${cuda_lib_val}#g'"
    if [ "${found_cudamath}" = "no" ]; then
        cudamath_val="${cuda_val}"
        if [ "${found_cudamath_inc}" = "no" ]; then
            cudamath_inc_val="${cuda_inc_val}"
        fi
        if [ "${found_cudamath_lib}" = "no" ]; then
            cudamath_lib_val="${cuda_lib_val}"
        fi
    else
        if [ "${found_cudamath_inc}" = "no" ]; then
            cudamath_inc_val="${cudamath_val}/include"
        fi
        if [ "${found_cudamath_lib}" = "no" ]; then
            cudamath_lib_val="${cudamath_val}/lib64"
        fi
    fi
    confsub="${confsub} -e 's#@CUDA_MATH@#${cudamath_val}#g'"
    confsub="${confsub} -e 's#@CUDA_MATH_INC@#${cudamath_inc_val}#g'"
    confsub="${confsub} -e 's#@CUDA_MATH_LIB@#${cudamath_lib_val}#g'"
fi

# We add these predefined matches at the end- so that the config
# file can actually use these as well.

compiled_prefix="${prefix}/cmbenv_aux"
python_prefix="${prefix}/cmbenv_python"
if [ "x${docker}" = "xyes" ]; then
    prefix="/usr/local"
    compiled_prefix="/usr/local"
    python_prefix="/usr/local"
fi

module_dir="${moddir}/cmbenv"

confsub="${confsub} -e 's#@SRCDIR@#${topdir}#g'"
confsub="${confsub} -e 's#@PREFIX@#${prefix}#g'"
confsub="${confsub} -e 's#@AUX_PREFIX@#${compiled_prefix}#g'"
confsub="${confsub} -e 's#@PYTHON_PREFIX@#${python_prefix}#g'"
confsub="${confsub} -e 's#@VERSION@#${version}#g'"
confsub="${confsub} -e 's#@MODULE_DIR@#${module_dir}#g'"

# If we are using docker, then the package scripts need to be able to find
# the tools that we have copied into the container.
if [ "x${docker}" = "xyes" ]; then
    confsub="${confsub} -e 's#@TOP_DIR@#/home/cmbenv#g'"
else
    confsub="${confsub} -e 's#@TOP_DIR@#${topdir}#g'"
fi
confsub="${confsub} -e 's#@DOCKER@#${docker}#g'"

# echo "${confsub}"

# Process each selected package for this config.  Copy each package file into
# the output location while substituting config variables.  Also build up the
# text that will be inserted into the template.

pkgcom=""

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^#.* ]]; then
        # This is a comment line
        echo "" >/dev/null
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
            pkgname=$(echo "${line}" | awk '{print $1}')
        fi

        # Copy the package file into place while applying the config.
        while IFS='' read -r pkgline || [[ -n "${pkgline}" ]]; do
            echo "${pkgline}" | eval sed ${confsub} >> "${topdir}/${outpkg}/${pkgname}.sh"
        done < "${topdir}/pkgs/${pkgname}.sh"
        chmod +x "${topdir}/${outpkg}/${pkgname}.sh"

        # Copy any patch file
        if [ -e "${topdir}/pkgs/patch_${pkgname}" ]; then
            cp -a "${topdir}/pkgs/patch_${pkgname}" "${topdir}/${outpkg}/"
        fi

        if [ "x${docker}" = "xyes" ]; then
            # Since we are usually doing a 2-stage docker build, we do not need to purge
            # source / build artifacts that will not be copied.  This also helps
            # debugging.
            #pcom="RUN cln=\$(./${outpkg}/${pkgname}.sh ${pkgopts}); if [ \$? -ne 0 ]; then echo \"FAILED\"; exit 1; fi; echo \${cln}; rm -rf \${cln}"
            pcom="RUN cln=\$(./${outpkg}/${pkgname}.sh ${pkgopts}); if [ \$? -ne 0 ]; then echo \"FAILED\"; exit 1; fi"
            pkgcom+="${pcom}"$'\n'$'\n'
        else
            pcom="cln=\$(${topdir}/${outpkg}/${pkgname}.sh ${pkgopts}); if [ \$? -ne 0 ]; then echo \"FAILED\"; exit 1; fi"
            pkgcom+="${pcom}"$'\n'$'\n'
        fi
    fi
done < "${pkgfile}"


# Now process the input template, substituting the list of package install
# commands that we just built.

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ @PACKAGES@ ]]; then
        echo "${pkgcom}" >> "${outfile}"
    else
        echo "${line}" | eval sed ${confsub} >> "${outfile}"
    fi
done < "${topdir}/templates/${template}"
chmod +x "${outfile}"


# Finally, create the module file and module version file for this config.
# Also create a shell snippet that can be sourced.

if [ "x${docker}" != "xyes" ]; then
    while IFS='' read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" =~ @modload@ ]]; then
            if [ -e "${confmodinit}" ]; then
                cat "${confmodinit}" >> "${outmod}"
            fi
        else
            echo "${line}" | eval sed ${confsub} >> "${outmod}"
        fi
    done < "${topdir}/templates/modulefile.in"

    while IFS='' read -r line || [[ -n "${line}" ]]; do
        echo "${line}" | eval sed ${confsub} >> "${outmodver}"
    done < "${topdir}/templates/version.in"

    echo "# Source this file from a Bourne-compatible shell to load" > "${outinit}"
    echo "# this cmbenv installation into your environment:" >> "${outinit}"
    echo "#" >> "${outinit}"
    echo "#   %>  . path/to/cmbenv_init.sh" >> "${outinit}"
    echo "#" >> "${outinit}"
    echo "# Then do \"source cmbenv\" as usual." >> "${outinit}"
    echo "#" >> "${outinit}"
    if [ -e "${confshinit}" ]; then
        cat "${confshinit}" >> "${outinit}"
    fi
    echo "unset PYTHONSTARTUP" >> "${outinit}"
    echo "export PYTHONUSERBASE=\$HOME/.local/cmbenv-${version}" >> "${outinit}"
    echo "export PATH=\"${python_prefix}/bin\":\${PATH}" >> "${outinit}"

fi
