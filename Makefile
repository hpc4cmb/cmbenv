
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

# The files with the build rules for each dependency

rules_full := $(wildcard pkgs/*)
rules_sh := $(foreach rl,$(rules_full),$(subst pkgs/,,$(rl)))
rules := $(foreach rl,$(rules_sh),$(subst .sh,,$(rl)))

# For depending on the helper scripts and templates

TOOLS := $(wildcard ./templates/*)

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
  CMBMODULEDIR := "$(CMBPREFIX)/modulefiles"
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


Dockerfile_$(CMBCONFIG) : $(CONFIG_FILE) $(TOOLS) Dockerfile.template
	@./templates/apply_conf.sh Dockerfile.template "Dockerfile_$(CMBCONFIG)" "$(CONFIG_FILE)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" yes

Dockerfile-intel_$(CMBCONFIG) : $(CONFIG_FILE) $(TOOLS) Dockerfile-intel.template
	@./templates/apply_conf.sh Dockerfile-intel.template "Dockerfile-intel_$(CMBCONFIG)" "$(CONFIG_FILE)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" yes


install_$(CMBCONFIG).sh : $(CONFIG_FILE) $(TOOLS) install.template
	@./templates/apply_conf.sh install.template "install_$(CMBCONFIG).sh" "$(CONFIG_FILE)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" no \
	&& chmod +x "install_$(CMBCONFIG).sh" \
	&& ./templates/gen_modulefile.sh templates/modulefile.in "install_$(CMBCONFIG).sh.modtemplate" "$(CONFIG_FILE).module" \
	&& ./templates/apply_conf.sh "install_$(CMBCONFIG).sh.modtemplate" "install_$(CMBCONFIG).sh.module" "$(CONFIG_FILE)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" no \
	&& ./templates/apply_conf.sh templates/version.in "install_$(CMBCONFIG).sh.modversion" "$(CONFIG_FILE)" "$(CMBPREFIX)" "$(CMBVERSION)" "$(CMBMODULEDIR)" no


Dockerfile.template : templates/Dockerfile.in $(rules_full) $(TOOLS)
	@./templates/gen_template.sh templates/Dockerfile.in Dockerfile.template "$(rules)" RUN

Dockerfile-intel.template : templates/Dockerfile-intel.in $(rules_full) $(TOOLS)
	@./templates/gen_template.sh templates/Dockerfile-intel.in Dockerfile-intel.template "$(rules)" RUN


install.template : templates/install.in $(rules_full) $(TOOLS)
	@./templates/gen_template.sh templates/install.in install.template "$(rules)"


clean :
	@rm -f Dockerfile* install*
