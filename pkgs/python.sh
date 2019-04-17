#!/bin/bash

# Install / configure a base python environment.
pkgopts=$@
cleanup=""

export pytype=$(echo "$pkgopts" | awk -e '{print $1}')
if [ "${pytype}" = "conda" ]; then
    echo "python using conda" >&2
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
    mkdir -p "@PYTHON_PREFIX@"
    echo "# Set up conda for cmbenv" > "@PYTHON_PREFIX@/cmbinit.sh"
    echo "source @PYTHON_PREFIX@/etc/profile.d/conda.sh" >> "@PYTHON_PREFIX@/cmbinit.sh"
    echo "conda config --set changeps1 False" >> "@PYTHON_PREFIX@/cmbinit.sh"
    echo "conda activate" >> "@PYTHON_PREFIX@/cmbinit.sh"
    echo "" >> "@PYTHON_PREFIX@/cmbinit.sh"
    bash "${inst}" -b -f -p "@PYTHON_PREFIX@" \
    && source "@PYTHON_PREFIX@/cmbinit.sh" \
    && conda install --copy --yes python=@PYVERSION@ \
    && ln -s "@PYTHON_PREFIX@/lib/libpython*" "@AUX_PREFIX@/lib/" \
    && conda install --copy --yes \
        nose \
        cython \
        numpy \
        scipy \
        matplotlib \
        pyyaml \
        astropy \
        psutil \
        ephem \
        virtualenv \
        pandas \
        memory_profiler \
        ipython \
        cmake \
    && rm -rf "@PYTHON_PREFIX@/pkgs/*"
    if [ $? -ne 0 ]; then
        echo "conda install failed" >&2
        exit 1
    fi
else
    if [ "${pytype}" = "virtualenv" ]; then
        echo "python using virtualenv" >&2
        mkdir -p "@PYTHON_PREFIX@"
        echo "# Set up virtualenv for cmbenv" > "@PYTHON_PREFIX@/cmbinit.sh"
        echo "export VIRTUAL_ENV_DISABLE_PROMPT=1" >> "@PYTHON_PREFIX@/cmbinit.sh"
        echo "source @PYTHON_PREFIX@/bin/activate" >> "@PYTHON_PREFIX@/cmbinit.sh"
        echo "" >> "@PYTHON_PREFIX@/cmbinit.sh"
        virtualenv -p python@PYVERSION@ "@PYTHON_PREFIX@" \
        && source "@PYTHON_PREFIX@/cmbinit.sh"
    else
        echo "python using default" >&2
        mkdir -p "@PYTHON_PREFIX@"
        echo "# Using default python for cmbenv" > "@PYTHON_PREFIX@/cmbinit.sh"
        echo "" >> "@PYTHON_PREFIX@/cmbinit.sh"
    fi
    pip install \
        nose \
        cython \
        numpy \
        scipy \
        matplotlib \
        pyyaml \
        astropy \
        psutil \
        ephem \
        pandas \
        memory_profiler \
        ipython \
        cmake
    if [ $? -ne 0 ]; then
        echo "pip install failed" >&2
        exit 1
    fi
fi
python -c "import matplotlib.font_manager"
if [ $? -ne 0 ]; then
    echo "python package imports failed" >&2
    exit 1
fi

echo "${cleanup}"
exit 0
