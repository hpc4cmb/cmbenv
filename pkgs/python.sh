#!/bin/bash

# Install / configure a base python environment.
pkgopts=$@
cleanup=""

pkg="python"

export pytype=$(echo "$pkgopts" | awk '{print $1}')
export cdatype=$(echo "$pkgopts" | awk '{print $2}')

mkdir -p "@PYTHON_PREFIX@/bin"

if [ "${pytype}" = "conda" ]; then
    echo "Python using conda" >&2
    if [ "@OSTYPE@" = "linux" ]; then
        inst=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh miniconda.sh)
    else
        if [ "@OSTYPE@" = "osx" ]; then
            inst=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh)
        else
            echo "Unsupported value for config option OSTYPE" >&2
            exit 1
        fi
    fi
    if [ "x${inst}" = "x" ]; then
        echo "Failed to fetch miniconda" >&2
        exit 1
    fi
    cleanup="${inst}"
    bash "${inst}" -b -f -p "@PYTHON_PREFIX@" \
    && echo "# condarc to force channel order" > "@PYTHON_PREFIX@/.condarc" \
    && echo "channels:" >> "@PYTHON_PREFIX@/.condarc" \
    && if [ "x${cdatype}" = "xnomkl" ]; then
        echo "  - conda-forge" >> "@PYTHON_PREFIX@/.condarc"
    fi \
    && echo "  - defaults" >> "@PYTHON_PREFIX@/.condarc" \
    && echo "changeps1: false" >> "@PYTHON_PREFIX@/.condarc" \
    && eval "@SRCDIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${cdatype}" \
    && source "@PYTHON_PREFIX@/bin/cmbenv" \
    && conda update -n base -c defaults --yes conda \
    && conda install --copy --yes python=@PYVERSION@ \
    && ln -s "@PYTHON_PREFIX@"/include/python* "@AUX_PREFIX@/include/" \
    && ln -s "@PYTHON_PREFIX@"/lib/libpython* "@AUX_PREFIX@/lib/"
    if [ $? -ne 0 ]; then
        echo "conda python install failed" >&2
        exit 1
    fi
    if [ "x${cdatype}" = "xnomkl" ]; then
        conda install --copy --yes "blas=*=openblas"
    else
        conda install --copy --yes blas
    fi
    if [ $? -ne 0 ]; then
        echo "conda blas install failed" >&2
        exit 1
    fi
    conda install --copy --yes \
        nose \
        cython \
        numpy \
        scipy \
        matplotlib \
        pyyaml \
        astropy \
        six \
        psutil \
        ephem \
        virtualenv \
        pandas \
        memory_profiler \
        ipython \
        cython \
        cycler \
        kiwisolver \
        python-dateutil \
        toml \
        numba \
        nbstripout \
        black \
        ipykernel \
    && rm -rf "@PYTHON_PREFIX@/pkgs/*"
    if [ $? -ne 0 ]; then
        echo "conda install packages failed" >&2
        exit 1
    fi
else
    if [ "${pytype}" = "virtualenv" ]; then
        echo "Python using virtualenv" >&2
        virtualenv -p python@PYVERSION@ "@PYTHON_PREFIX@" \
        && eval "@SRCDIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${cdatype}" \
        && source "@PYTHON_PREFIX@/bin/cmbenv"
    else
        echo "Python using default" >&2
        eval "@SRCDIR@/tools/gen_activate.sh" "@VERSION@" "@PREFIX@" "@PYTHON_PREFIX@" "@AUX_PREFIX@" "@PYVERSION@" "${pytype}" "${cdatype}" \
        && source "@PYTHON_PREFIX@/bin/cmbenv"
    fi
    pip3 install \
        nose \
        cython \
        numpy \
        scipy \
        matplotlib \
        pyyaml \
        astropy \
        six \
        psutil \
        ephem \
        pandas \
        memory_profiler \
        ipython \
        cython \
        cycler \
        kiwisolver \
        python-dateutil \
        toml \
        numba \
        nbstripout \
        black \
        ipykernel
    if [ $? -ne 0 ]; then
        echo "pip install failed" >&2
        exit 1
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
