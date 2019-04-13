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

Create or edit a file in the "configs" subdirectory that is named whatever you like.  This file will define compilers, flags, etc.
Optionally create files with the same name and the ".module" and ".sh"
suffixes.  These optional files should contain any modulefile and shell
commands needed to set up the environment prior to building the tools or loading them later.  See existing files for
examples.

To create a config for a docker image, the config file must be prefixed
with "docker-".  You should not have any "*.module" or "*.sh" files for
a docker config.


## Generate the Script

Set the CMBCONFIG, CMBPREFIX, and (optionally) the CMBVERSION and CMBMODULEDIR environment
variables.  Then create the script with::

    %> make script

To clean up all generated scripts, do::

    %> make clean

For normal installs, this creates an install script and corresponding
module files.  For docker builds, a Dockerfile is created.  As an example,
suppose we are installing the software stack into our scratch directory
on cori.nersc.gov using the intel config::

    %> CMBPREFIX=${SCRATCH}/software/cmbenv_cori-intel CMBCONFIG=cori-intel \
       make clean
    %> CMBPREFIX=${SCRATCH}/software/cmbenv_cori-intel CMBCONFIG=cori-intel \
       make script

If you don't have the $CMBVERSION environment variable set, then a version
string based on the git revision history is used.  If you don't have the
$CMBMODULEDIR environment variable set, then the modulefiles will be installed
to $CMBPREFIX/modulefiles.


## Installation

For normal installs, simply run the install script.  This installs the
software and modulefile, as well as a module version file named
`.version_$CMBVERSION` in the module install directory.  You can manually
move this into place if and when you want to make that the default
version.  You can run the install script from an alternate build
directory.  

For docker installs, run docker build from the same directory as the
generated Dockerfile, so that the path to data files can be found.  Making
docker images requires a working docker installation.  You
should familiarize yourself with the docker tool before attempting to use
it here.

As an example, suppose we want to install the script we made in the
previous section for cori.  We'll make a temporary directory on
scratch to do the building, since it is going to download and compile
several big packages.  We'll also dump all output to a log file so that
we can look at it afterwards if there are any problems::

    %> cd $SCRATCH
    %> mkdir build
    %> cd build
    %> /path/to/git/cmbenv/install_cori-intel.sh >log 2>&1 &
    %> tail -f log

After installation, the $CMBPREFIX directory will contain directories
and files::

    $CMBPREFIX/$CMBVERSION_conda
    $CMBPREFIX/$CMBVERSION_aux
    $CMBPREFIX/modulefiles/cmbenv/$CMBVERSION
    $CMBPREFIX/modulefiles/cmbenv/.version_$CMBVERSION

If you want to make this version of cmbenv the default, then just
do::

    %> cd $CMBPREFIX/modulefiles/cmbenv
    %> rm -f .version && ln -s .version_$CMBVERSION .version

## Push the Docker container to Docker Hub

It is recommended to tag the container with the hash of the cmbenv git repository.
In the following snippets, I assume that username is the same on
local machine, Github, DockerHub and NERSC.
Build it with:

    %> docker build . -t $USER/cmbenv:$(git rev-parse --short HEAD)

Then, login to <https://hub.docker.com> with your Github credentials and create a new
repository named `cmbenv`, then push the image you just built to DockerHub:

    %> docker login
    %> docker push $USER/cmbenv:$(git rev-parse --short HEAD)

## Use the Docker container at NERSC with shifter

See the [NERSC documentation about shifter](http://www.nersc.gov/users/software/using-shifter-and-docker/using-shifter-at-nersc/).

First login to Cori and pull the image from Docker Hub:

    %> shifterimg pull $USER/cmbenv:xxxxxx

This is going to take a few minutes. Then you can test this interactively:

    %> salloc -N 1 -p debug --image=docker:YOURUSERNAME/cmbenv:xxxxxx \
       -t 00:30:00
    %> shifter /bin/bash

To use this image in a slurm batch script, just add:

    #SBATCH --image=docker:YOURUSERNAME/cmbenv:xxxxx

In the SLURM header to set the image. Then prepend `shifter` to all running
commands (after `srun` and all its options).  For example, to run a script in the container:

    srun -n 1 -N 1 shifter myscript.py

If you are running any command in the container, make sure to prepend the shifter command.  For example:

    shifter which myscript.py
