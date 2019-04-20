#!/bin/bash

# Install / configure a base python environment.
pkgopts=$@
cleanup=""

pkg="python"

export pytype=$(echo "$pkgopts" | awk '{print $1}')

mkdir -p "@PYTHON_PREFIX@"
cload="@PYTHON_PREFIX@/cmbload.sh"
cunload="@PYTHON_PREFIX@/cmbunload.sh"

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
    # Load / unload scripts
    echo "# Set up conda for cmbenv" > "${cload}"
    echo "source @PYTHON_PREFIX@/etc/profile.d/conda.sh" >> "${cload}"
    echo "conda config --set changeps1 False" >> "${cload}"
    echo "conda activate" >> "${cload}"
    echo "" >> "${cload}"
    echo "# Unload conda for cmbenv" > "${cunload}"
    echo "conda deactivate" >> "${cunload}"
    echo "" >> "${cunload}"
    bash "${inst}" -b -f -p "@PYTHON_PREFIX@" \
    && source "${cload}" \
    && conda install --copy --yes python=@PYVERSION@ \
    && ln -s "@PYTHON_PREFIX@"/lib/libpython* "@AUX_PREFIX@/lib/" \
    && conda install --copy --yes \
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
        pkgconfig \
        cycler \
        kiwisolver \
        python-dateutil \
        cmake \
    && rm -rf "@PYTHON_PREFIX@/pkgs/*"
    if [ $? -ne 0 ]; then
        echo "conda install failed" >&2
        exit 1
    fi
else
    if [ "${pytype}" = "virtualenv" ]; then
        echo "Python using virtualenv" >&2
        echo "# Set up virtualenv for cmbenv" > "${cload}"
        echo "export VIRTUAL_ENV_DISABLE_PROMPT=1" >> "${cload}"
        echo "source @PYTHON_PREFIX@/bin/activate" >> "${cload}"
        echo "" >> "${cload}"
        echo "# Unload conda for cmbenv" > "${cunload}"
        echo "conda deactivate" >> "${cunload}"
        echo "" >> "${cunload}"
        virtualenv -p python@PYVERSION@ "@PYTHON_PREFIX@" \
        && source "${cload}"
    else
        echo "Python using default" >&2
        echo "# Using default python for cmbenv" > "${cload}"
        echo "" >> "${cload}"
        echo "# Using default python for cmbenv" > "${cunload}"
        echo "" >> "${cunload}"
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
        pkgconfig \
        cycler \
        kiwisolver \
        python-dateutil \
        cmake
    if [ $? -ne 0 ]; then
        echo "pip install failed" >&2
        exit 1
    fi
fi
python -c "import matplotlib.font_manager"
if [ $? -ne 0 ]; then
    echo "Python package imports failed" >&2
    exit 1
fi

echo "Finished installing ${pkg}" >&2
echo "${cleanup}"
exit 0
