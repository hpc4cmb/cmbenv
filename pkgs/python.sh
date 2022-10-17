#!/bin/bash

# Install / configure a base python environment.
pkgopts=$@
cleanup=""

pkg="python"

export pytype=$(echo "$pkgopts" | awk '{print $1}')
export pextra=$(echo "$pkgopts" | awk '{print $2}')

mkdir -p "@PYTHON_PREFIX@/bin"

if [ "${pytype}" = "conda" ]; then
    echo "Python using conda" >&2
    if [ "@OSTYPE@" = "linux" ]; then
        inst=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh miniforge.sh)
    else
        if [ "@OSTYPE@" = "osx" ]; then
            inst=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-$(uname -m).sh miniforge.sh)
        else
            echo "Unsupported value for config option OSTYPE" >&2
            exit 1
        fi
    fi
    if [ "x${inst}" = "x" ]; then
        echo "Failed to fetch miniforge" >&2
        exit 1
    fi
    cleanup="${inst}"
    bash "${inst}" -b -f -p "@PYTHON_PREFIX@" \
    && echo "# condarc for cmbenv" > "@PYTHON_PREFIX@/.condarc" \
    && echo "changeps1: false" >> "@PYTHON_PREFIX@/.condarc" \
    && eval "@TOP_DIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${pextra}" \
    && source "@PYTHON_PREFIX@/bin/cmbenv" \
    && conda install --copy --yes python=@PYVERSION@ \
    && conda update --yes -n base conda \
    && ln -s "@PYTHON_PREFIX@"/include/python* "@AUX_PREFIX@/include/" \
    && ln -s "@PYTHON_PREFIX@"/lib/libpython* "@AUX_PREFIX@/lib/" \
    && rm -f "@PYTHON_PREFIX@/compiler_compat/ld"
    if [ $? -ne 0 ]; then
        echo "conda python install failed" >&2
        exit 1
    fi
    if [ "x${pextra}" = "xmkl" ]; then
        conda install --copy --yes "libblas=*=*mkl" numpy
    else
        conda install --copy --yes "libblas=*=*openblas" "_openmp_mutex=*=*_gnu" numpy
    fi
    if [ $? -ne 0 ]; then
        echo "conda libblas / numpy install failed" >&2
        exit 1
    fi
    if [ "x@CONDA_PKGS@" != "x" ]; then
        conda install --copy --yes @CONDA_PKGS@
    fi
    if [ $? -ne 0 ]; then
        echo "conda install packages failed" >&2
        exit 1
    fi
    rm -rf "@PYTHON_PREFIX@/pkgs/*"
else
    if [ "${pytype}" = "virtualenv" ]; then
        echo "Python using virtualenv" >&2
        virtualenv -p python@PYVERSION@ "@PYTHON_PREFIX@" \
        && eval "@TOP_DIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${pextra}" \
        && source "@PYTHON_PREFIX@/bin/cmbenv"
    else
        echo "Python using default" >&2
        eval "@TOP_DIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${pextra}" \
        && source "@PYTHON_PREFIX@/bin/cmbenv"
    fi
    # Upgrade pip and wheel
    pip3 install --upgrade pip setuptools wheel >&2
    if [ "x@PIP_PKGS@" != "x" ]; then
        for pip_pkg in @PIP_PKGS@; do
            pip3 install ${pip_pkg} >&2
            if [ $? -ne 0 ]; then
                echo "pip install of ${pip_pkg} failed" >&2
                exit 1
            fi
        done
    fi
fi
python3 -c "import matplotlib.font_manager"
if [ $? -ne 0 ]; then
    echo "Python package imports failed" >&2
    exit 1
fi

# Ensure that python-config always points to this install
if [ ! -e "@PYTHON_PREFIX@/bin/python-config" ]; then
    if [ -e "@PYTHON_PREFIX@/bin/python3-config" ]; then
        ln -s "@PYTHON_PREFIX@/bin/python3-config" "@PYTHON_PREFIX@/bin/python-config"
    fi
fi

# Create a launcher script for jupyter
kern="@PYTHON_PREFIX@/bin/cmbenv_run_kernel.sh"
echo "#!/bin/bash" > "${kern}"
echo "conn=\$1" >> "${kern}"
echo "cmbpy=@PYTHON_PREFIX@" >> "${kern}"
echo "source \"\${cmbpy}/bin/cmbenv\"" >> "${kern}"
echo "exec python3 -m ipykernel -f \${conn}" >> "${kern}"
chmod +x "${kern}"

echo "Finished installing ${pkg}" >&2
echo "${cleanup}"
exit 0
