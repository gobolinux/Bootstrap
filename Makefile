# Makefile for Bootstrap
#
# Copyright (C) 1999-2005 by Erik Andersen <andersen@codepoet.org>
#
# Modifications by Lucas C. Villa Real <lucasvr@gobolinux.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

#--------------------------------------------------------------
# Just run 'make menuconfig', configure stuff, then run 'make'.
# You shouldn't need to mess with anything beyond this point...
#--------------------------------------------------------------
TOPDIR=./
CONFIG_CONFIG_IN = Config.in
CONFIG_DEFCONFIG = .defconfig
CONFIG = scripts

noconfig_targets := menuconfig config oldconfig randconfig \
	defconfig allyesconfig allnoconfig clean distclean \
	release tags

# Pull in the user's configuration file
ifeq ($(filter $(noconfig_targets),$(MAKECMDGOALS)),)
-include $(TOPDIR).config
endif

# aunpack verbosity level
ifeq ($(UNPACK_VERBOSITY),y)
UNPACK_OPTIONS=--verbosity=1
else
UNPACK_OPTIONS=--quiet
endif

ifeq ($(strip $(HAVE_DOT_CONFIG)),y)

all: world

# In this section, we need .config
include .config.cmd

TARGETS_CLEAN:=$(patsubst %,%-clean,$(TARGETS))
TARGETS_SOURCE:=$(patsubst %,%-source,$(TARGETS))

help:
	@echo 'Automatic dependency selection:'
	@echo '  dep          - Selects all packages marked as a dependency for the chosen ones'
	@echo ''
	@echo 'Cleaning targets:'
	@echo '  clean        - Remove most generated files but keep the config'
	@echo ''
	@echo 'Configuration targets:'
	@echo '  menuconfig   - Update current config utilising a menu based program'
	@echo ''
	@echo 'Creating images:'
	@echo '  ramdisk      - Creates an image from the filesystem for usage as a ramdisk'
	@echo '  iso          - Creates a Rocket-Ridge/Joliet ISO image from the filesystem'
	@echo ''
	@echo 'Other generic targets:'
	@echo '  all          - Build all targets marked with [*]'
	@echo '  shrink       - Performs a cleanup on the generated tree'
	@echo '  descriptions - Update package descriptions'
	@echo '  make V=0|1   - Quiet or verbose build (default)'
	@echo ''
	@echo 'Execute "make" or "make all" to build all targets marked with [*]'
	@echo 'For further info see the ./README file'
	@echo ''

VERBOSE_BUILD=0
ifdef V
	VERBOSE_BUILD=$(V)
endif

deps:
	@cd bin && ./MakeDeps ../.config

dep: deps

shrink:
	@cd bin; ./Shrink

descriptions:
	@bin/CreateDescriptions

ramdisk:
	@bin/CreateImage ramdisk $(DIR) $(SIZE)

iso:
	@bin/CreateImage iso $(DIR)

world: $(TARGETS)
	@cd bin; ./BootStrap start                || { ./BootStrap stop; exit 1; }
	@cd bin; ./PrepareTarget                  || { ./BootStrap stop; exit 1; }
	@cd bin; ./InvokeCompile $(VERBOSE_BUILD) || { ./BootStrap stop; exit 1; }
	@cd bin; ./FixupEnvironment               || { ./BootStrap stop; exit 1; }
	@echo -e "\nRoot filesystem created successfully!"
	@echo -e "Have a good time with GoboLinux on your new platform!\n"
	@cd bin; ./BootStrap stop

.PHONY: all world clean distclean source $(TARGETS) \
	$(TARGETS_CLEAN) $(TARGETS_SOURCE)

#############################################################
#
# target directory - do NOT list it as a dependency anywhere 
# else
#
#############################################################
source: $(TARGETS_SOURCE)

#############################################################
#
# Cleanup and misc junk
#
#############################################################
clean: $(TARGETS_CLEAN)
	rm -rf $(IMAGE)

distclean: clean

else # ifneq ($(strip $(HAVE_DOT_CONFIG)),y)

shrink:
	@echo "Please run make menuconfig first"

all:
	@echo "Please run make menuconfig first"

# configuration
# ---------------------------------------------------------------------------

$(CONFIG)/conf:
	$(MAKE) -C $(CONFIG) conf
	-@if [ ! -f .config ] ; then \
		cp $(CONFIG_DEFCONFIG) .config; \
	fi
$(CONFIG)/mconf:
	$(MAKE) -C $(CONFIG) ncurses conf mconf
	-@if [ ! -f .config ] ; then \
		cp $(CONFIG_DEFCONFIG) .config; \
	fi

menuconfig: $(CONFIG)/mconf
	@$(CONFIG)/mconf $(CONFIG_CONFIG_IN)

config: $(CONFIG)/conf
	@$(CONFIG)/conf $(CONFIG_CONFIG_IN)

oldconfig: $(CONFIG)/conf
	@$(CONFIG)/conf -o $(CONFIG_CONFIG_IN)

randconfig: $(CONFIG)/conf
	@$(CONFIG)/conf -r $(CONFIG_CONFIG_IN)

allyesconfig: $(CONFIG)/conf
	#@$(CONFIG)/conf -y $(CONFIG_CONFIG_IN)
	#sed -i -e "s/^CONFIG_DEBUG.*/# CONFIG_DEBUG is not set/" .config
	@$(CONFIG)/conf -o $(CONFIG_CONFIG_IN)

allnoconfig: $(CONFIG)/conf
	@$(CONFIG)/conf -n $(CONFIG_CONFIG_IN)

defconfig: $(CONFIG)/conf
	@$(CONFIG)/conf -d $(CONFIG_CONFIG_IN)

#############################################################
#
# Cleanup and misc junk
#
#############################################################
clean:
	- $(MAKE) -C $(CONFIG) clean

distclean: clean
	rm -f .config .config.old .config.cmd .tmpconfig.h
	rm -rf sources/*

endif # ifeq ($(strip $(HAVE_DOT_CONFIG)),y)

.PHONY: dummy subdirs release distclean clean config oldconfig \
	menuconfig tags check test depend defconfig
