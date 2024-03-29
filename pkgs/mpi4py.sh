#!/bin/bash

pkg="mpi4py"
pkgopts=$@
cleanup=""

# Note:  update the URL when you change the version.
version=3.1.3

pfile=mpi4py-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://files.pythonhosted.org/packages/20/50/d358fe2b56075163b75eca30c2faa6455c50b9978dd26f0fc4e3879b1062/${pfile} ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

if [ "@DOCKER@" = "yes" ]; then
    log=/dev/stderr
else
    log="../log_${pkg}"
fi

echo "Building ${pkg}..." >&2

rm -rf mpi4py-${version}
tar xzf ${src} \
    && cd mpi4py-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && echo "[mpi]" > mpi.cfg \
    && echo "mpicc = @MPICC@" >> mpi.cfg \
    && echo "mpicxx = @MPICXX@" >> mpi.cfg \
    && echo "include_dirs = @MPI_CPPFLAGS@" >> mpi.cfg \
    && echo "library_dirs = @MPI_LDFLAGS@" >> mpi.cfg \
    && echo "runtime_library_dirs = @MPI_LDFLAGS@" >> mpi.cfg \
    && echo "libraries = @MPI_LIB@" >> mpi.cfg \
    && echo "extra_compile_args = @MPI_EXTRA_COMP@" >> mpi.cfg \
    && echo "extra_link_args = @MPI_EXTRA_LINK@" >> mpi.cfg \
    && CC="@CC@" CFLAGS="@MPI_EXTRA_COMP@" \
    python3 setup.py install --prefix="@AUX_PREFIX@" > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
