#!/bin/bash

# Install python packages
pkgopts=$@
cleanup=""

pkg="python_pkgs"

conda_exec=$(which conda)

if [ "x${conda_exec}" != "x" ]; then
    # We have a conda environment.  Install any packages.
    if [ "x@CONDA_PKGS@" != "x" ]; then
        conda install --copy --yes @CONDA_PKGS@
    fi
    if [ $? -ne 0 ]; then
        echo "conda install packages failed" >&2
        exit 1
    fi
    rm -rf "@PYTHON_PREFIX@/pkgs/*"
fi

if [ "x@PIP_PKGS@" != "x" ]; then
    for pip_pkg in @PIP_PKGS@; do
        pip3 install ${pip_pkg} >&2
        if [ $? -ne 0 ]; then
            echo "pip install of ${pip_pkg} failed" >&2
            exit 1
        fi
    done
fi

python3 -c "import matplotlib.font_manager"
if [ $? -ne 0 ]; then
    echo "Python package imports failed" >&2
    exit 1
fi

echo "Finished installing ${pkg}" >&2
echo "${cleanup}"
exit 0
