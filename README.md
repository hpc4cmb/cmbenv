# cmbenv

## Introduction

The CMB field uses a variety of software packages.  Many tools are Python based
and can easily be installed with conda or pip.  Others are more challenging to
install from source, which is often required for non-standard environments like
HPC systems.  The goal of this git repo is to make it "easier" to install many
of these packages while getting simpler tools from Python packages when
possible.

In particular, some systems may require building tools from scratch in order to
be compatible with a specialized compiler toolchain.  Other systems that are a
standard Linux flavor and less performance critical may get some tools from the
OS package manager, conda, pip, etc.


## Configuration

If you are installing on a Linux or OS X workstation you may be able to use one of the existing build configurations.  Here is a decision tree to help guide the selection:

    Linux:  Is your system python3 fairly recent (>= 3.6.0)?
        - YES.  Do you want to use Anaconda python for some reason?
            - YES.  Do you want to use MKL for your own compiled python extensions?
                - Yes.  Use the linux-conda-nomkl config, so that numpy uses OpenBLAS.
                - No.  Use the linux-conda config.
            - NO.  Use the linux-venv config.  See MKL notes below.
        - NO.  You should use the linux-conda or linux-conda-nomkl config.
    OS X:  Are you currently using macports or homebrew to get a newer python3?
        - YES.  Do you want to use Fortran packages (libmadam)?
            - YES.  Install GNU compilers with macports or homebrew.
                    Use the macos-venv-gcc config.
            - NO.  Use the macos-venv-clang config.
        - NO.  Do you want to use Fortran packages (libmadam)?
            - YES.  Install GNU compilers with macports or homebrew.
                    Use the macos-conda-gcc config.
            - NO.  Use the macos-conda-clang config.

### Special Notes for OS X

Apple's operating system can be challenging to work with when building larger compiled packages that do not use X Code.  The native compilers do not support some languages and features, and installing external compilers (gcc) require care to ensure that all dependencies are also built with the same compiler.  Here are some recommendations:

  - Whenever you update your OS, also ensure that X Code and the commandline tools have been updated.

  - If using macports or homebrew, wipe and reinstall these when you upgrade your OS to a new version.

If you have trouble with python or gcc on OS X, try testing the "macos-conda-clang" config.  This should be the most stand-alone solution since it uses only the system clang compiler.  Downsides of this are the lack of fortran support and perhaps other features like OpenMP threading.

### MKL Warning

Some versions of numpy use a bundled version of MKL and the Intel threading libraries for linear algebra.  Some packages in `cmbenv` have compiled extensions that also link to external BLAS / LAPACK libraries.  The linear algebra libraries specified in the `BLAS` and `LAPACK` config variables must either be *different* from those used by numpy or **identical** to those used by numpy.

Since it is very challenging to control what upstream MKL is used by numpy, we take a different approach:

  - If you want to use the Intel compilers and MKL when building packages with `cmbenv`, please ensure that your numpy is NOT using MKL (for example, but choosing the "conda nomkl" option for the python package in the config files).

  - If you are using OpenBLAS (external or built by `cmbenv`) or the Apple accelerate framework, then you should not have any conflicts regardless of what numpy is using.

More details:  If you have a compiled extension that is linking to MKL and numpy is also
linked to a (different) MKL, then only one MKL version will be dlopen'ed by the dynamic
library loader.  So the order of python imports will determine which one gets loaded.
Even if the MKL versions are binary compatible, they may link to different threading
interface libraries.  For example, numpy ships with a bundled version of the Intel
threading library.  If your extension is built with gcc and linked to MKL, it will link
to the GNU interface library.

### Custom Configurations

Create or edit a file in the "configs" subdirectory that is named whatever you like.
This file will define compilers, flags, etc. Optionally create files with the same name
and the ".module" and ".sh" suffixes.  These optional files should contain any
modulefile and shell commands needed to set up the environment prior to building the
tools or loading them later.  The ".pkgs" file defines the packages to build for your
system.  See existing files for examples.  

To create a config for a docker image, the config file must be prefixed
with "docker-".  You should not have any "*.module" or "*.sh" files for
a docker config.


## Generate the Script

Use the top-level "cmbenv" script to generate an install script or docker file::

    %> ./cmbenv -c <config> -p <prefix> [-v <version] [-m <moduledir>]

For example::

    %> ./cmbenv -c linux-venv -p ${HOME}/cmbenv -v test


## Installation

For normal installs, simply run the install script.  I recommend doing this in a
"build" directory to avoid cluttering the source.  Continuing the previous
example::

    %> mkdir build; cd build
    %> ../install_linux-venv.sh | tee log

This installs the software and modulefile, as well as a module version file
named `.version_$CMBVERSION` in the module install directory.  You can manually
move this into place if and when you want to make that the default version.  It
also creates a simple shell snippet that you can source instead of using
modules.  

### Loading the Software

Continuing the example some more, load the above products into your environment
with::

    %> module use ${HOME}/cmbenv/modulefiles
    %> module load cmbenv

OR::

    %> source ${HOME}/cmbenv/cmbenv.sh


## Docker

For docker installs, run docker build from the same directory as the
generated Dockerfile, so that the path to data files can be found.  Making
docker images requires a working docker installation.  You
should familiarize yourself with the docker tool before attempting to use
it here.

It is recommended to tag the container with the hash of the cmbenv git
repository. In the following snippets, I assume that username is the same on
local machine, Github, DockerHub and NERSC. Build it with (for example):

    %> docker build -t $USER/cmbenv:$(git rev-parse --short HEAD) \
       -f Dockerfile_docker-py3.8-debian .

### Push the Docker container to Docker Hub

Login to <https://hub.docker.com> with your Github credentials and create
a new repository named `cmbenv`, then push the image you just built to
DockerHub:

    %> docker login
    %> docker push $USER/cmbenv:$(git rev-parse --short HEAD)

### Use the Docker container at NERSC with shifter

See the [NERSC documentation about shifter](http://www.nersc.gov/users/software/using-shifter-and-docker/using-shifter-at-nersc/).

First login to Cori and pull the image from Docker Hub:

    %> shifterimg pull $USER/cmbenv:xxxxxx

This is going to take a few minutes. Then you can test this interactively:

    %> salloc -N 1 -C haswell -p debug \
       --image=docker:YOURUSERNAME/cmbenv:xxxxxx \
       -t 00:30:00
    %> shifter /bin/bash

To use this image in a slurm batch script, just add:

    #SBATCH --image=docker:YOURUSERNAME/cmbenv:xxxxx

In the SLURM header to set the image. Then prepend `shifter` to all running commands
(after `srun` and all its options).  For example, to run a script in the container:

    srun -n 1 -N 1 shifter myscript.py

If you are running any command in the container, make sure to prepend the shifter
command.  For example:

    shifter which myscript.py
