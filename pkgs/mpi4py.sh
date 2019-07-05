#!/bin/bash

pkg="mpi4py"
pkgopts=$@
cleanup=""

pfile=mpi4py-3.0.1.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/55/a2/c827b196070e161357b49287fa46d69f25641930fd5f854722319d431843/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log="../log_${pkg}"

echo "Building ${pkg}..." >&2

rm -rf mpi4py-3.0.1
tar xzf ${src} \
    && cd mpi4py-3.0.1 \
    && echo "[toast]" > mpi.cfg \
    && echo "mpicc = @MPICC@" >> mpi.cfg \
    && echo "mpicxx = @MPICXX@" >> mpi.cfg \
    && echo "include_dirs = @MPI_CPPFLAGS@" >> mpi.cfg \
    && echo "library_dirs = @MPI_LDFLAGS@" >> mpi.cfg \
    && echo "runtime_library_dirs = @MPI_LDFLAGS@" >> mpi.cfg \
    && echo "libraries = @MPI_LIB@" >> mpi.cfg \
    && echo "extra_compile_args = @MPI_EXTRA_COMP@" >> mpi.cfg \
    && echo "extra_link_args = @MPI_EXTRA_LINK@" >> mpi.cfg \
    && python3 setup.py build --mpi=toast > ${log} 2>&1 \
    && python3 setup.py install --prefix="@AUX_PREFIX@" >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
