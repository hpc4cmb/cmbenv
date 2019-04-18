
SHELL = /bin/bash

# Check required environment variables

ifndef CMBCONFIG
  CMBCONFIG := $(error CMBCONFIG undefined)undefined
endif

gitdesc := $(shell git describe --tags --dirty --always | cut -d "-" -f 1)
gitcnt := $(shell git rev-list --count HEAD)

GITVERSION := "$(gitdesc).dev$(gitcnt)"
ifndef CMBVERSION
  CMBVERSION := $(GITVERSION)
endif

# Make seems to delete these...

.PRECIOUS : $(wildcard configs/*)

# Override arcane Make suffix rule for SCCS which
# wipes our config scripts...

% : %.sh

# Config related files

CONFIG_FILE := configs/$(CMBCONFIG)
CONFIG_PKGS := $(CONFIG_FILE).pkgs
CONFIG_MODINIT := $(CONFIG_FILE).mod

# For depending on the helper scripts and templates

TOOLS := $(wildcard ./templates/*) $(wildcard ./tools/*)

# Based on the config file name, are we building a docker file
# or an install script?

DOCKERCHECK := $(findstring docker,$(CMBCONFIG))
INTELCHECK := $(findstring intel,$(CMBCONFIG))
ifeq "$(DOCKERCHECK)" "docker"
ifeq "$(INTELCHECK)" "intel"
  SCRIPT := Dockerfile-intel_$(CMBCONFIG)
else
  SCRIPT := Dockerfile_$(CMBCONFIG)
endif
else
  SCRIPT := install_$(CMBCONFIG).sh
  ifndef CMBPREFIX
    CMBPREFIX := $(error CMBPREFIX undefined)undefined
  endif
endif

# Allow manually specifying the modulefiles directory.
# Otherwise install to PREFIX/modulefiles

ifndef CMBMODULEDIR
  CMBMODULEDIR := "$(CMBPREFIX)_$(CMBVERSION)/modulefiles"
endif


.PHONY : help script clean


help :
	@echo " "
	@echo " Before using this Makefile, set the CMBCONFIG and CMBPREFIX"
	@echo " environment variables.  The CMBVERSION environment variable is"
	@echo " optional.  The following targets are supported:"
	@echo " "
	@echo "    script  : Build the appropriate install script or Dockerfile."
	@echo "    clean   : Clean all generated files."
	@echo " "


script : $(CONFIG_FILE) $(TOOLS) $(SCRIPT)
	@echo "" >/dev/null


Dockerfile_$(CMBCONFIG) : $(CONFIG_FILE) $(TOOLS)
	@./tools/gen_script.sh Dockerfile.in "$(CONFIG_FILE)" "$(CONFIG_PKGS)" "$(CONFIG_MODINIT)" "Dockerfile_$(CMBCONFIG)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" yes

Dockerfile-intel_$(CMBCONFIG) : $(CONFIG_FILE) $(TOOLS)
	@./tools/gen_script.sh Dockerfile-intel.in "$(CONFIG_FILE)" "$(CONFIG_PKGS)" "$(CONFIG_MODINIT)" "Dockerfile-intel_$(CMBCONFIG)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" yes

install_$(CMBCONFIG).sh : $(CONFIG_FILE) $(TOOLS)
	@./tools/gen_script.sh install.in "$(CONFIG_FILE)" "$(CONFIG_PKGS)" "$(CONFIG_MODINIT)" "install_$(CMBCONFIG)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" no


clean :
	@rm -rf Dockerfile* install*
