#   Stage: Variables
ifeq ($(yaamake_stage),v)
# =======================

# Helper variables
# ----------------

CCVERSION_CPP11_OK := $(call version_compare,$(CCVERSION),>=,4.7)
CCVERSION_CPP14_OK := $(call version_compare,$(CCVERSION),>=,5.0)

# Common Compiler Options
# -----------------------

# Standards
CSTANDARD ?= -std=c99
CXXSTANDARD ?= $(if $(CCVERSION_CPP14_OK),-std=c++14,$(if $(CCVERSION_CPP11_OK),-std=c++11,-std=c++0x))

# Place your -D or -U options here
# DEFS +=

# Output format. (can be srec, ihex, binary)
FORMAT ?= ihex

# Build files directory
#     To put object files in current directory, use a dot (.)
override BUILDDIR := $(if $(BUILDDIR),$(BUILDDIR),$(CACHEDIR)/build)

# Optimization level, can be [0, 1, 2, 3, s].
#     0 = turn off optimization. s = optimize for size.
#     (Note: 3 is not always the best optimization level. See avr-libc FAQ.)
OPT ?= 2

# Debugging format.
#     Native formats for AVR-GCC's -g are dwarf-2 [default] or stabs.
#     AVR Studio 4.10 requires dwarf-2.
#     AVR [Extended] COFF format requires stabs, plus an avr-objcopy run.
DEBUG ?= dwarf-2




# Common Compiler Options
# -----------------------
#  -g*:          generate debugging information
#  -O*:          optimization level
#  -f...:        tuning, see GCC manual and avr-libc documentation
#  -Wa,...:   tell GCC to pass this to the assembler.
#    -adhlns: create listing
#    -gstabs: have the assembler create line number information; note that
#             for use in COFF files, additional information about filenames
#             and function names needs to be present in the assembler source
#             files -- see avr-libc docs [FIXME: not yet described there]
#    -listing-cont-lines: Sets the maximum number of continuation lines of hex
#             dump that will be displayed for a given single line of source input.

# target arch, with avr-gcc this means MCU
TARGET_ARCH = -mmcu=$(MCU)

# preprocessor options
CPPFLAGS += -g$(DEBUG)
CPPFLAGS += $(DEFS)
CPPFLAGS += $(if $(F_CPU),-DF_CPU=$(patsubst %kHz,%000,$(patsubst %MHz,%000000,$(F_CPU:%UL=%)))UL,)
CPPFLAGS += $(if $(F_CLOCK),-DF_CLOCK=$(patsubst %kHz,%000,$(patsubst %MHz,%000000,$(F_CLOCK:%UL=%)))UL,)
CPPFLAGS += -MMD -MP -MF $(patsubst %,%.dep,$(basename $@)$(suffix $<)) # generate dependency files.

# optimizer options
COFLAGS += -O$(OPT)
COFLAGS += -funsigned-char
COFLAGS += -funsigned-bitfields
COFLAGS += -ffunction-sections
COFLAGS += -fpack-struct
COFLAGS += -fshort-enums
COFLAGS += -ffreestanding
COFLAGS += -fno-exceptions
COFLAGS += -fno-threadsafe-statics
COFLAGS += $(if $(CCVERSION_CPP11_OK),-flto,) # required here to have any effect on linking
#COFLAGS += -fno-unit-at-a-time

# warning options
CWFLAGS += -Wall
CWFLAGS += -Wundef
CWFLAGS += -Wsign-compare
#CWFLAGS += -Wunreachable-code

# assembler options
CAFLAGS += -Wa,-adhlns=$(@:%.o=%.lst)

# include dirs
CIFLAGS += -I. $(patsubst %,-I%,$(EXTRAINCDIRS))



# Compiler options per source
# ---------------------------
CFLAGS  = $(CSTANDARD)
CFLAGS += $(COFLAGS)
CFLAGS += $(CWFLAGS)
CFLAGS += -Wstrict-prototypes
CFLAGS += $(CAFLAGS)
CFLAGS += $(CIFLAGS)

CXXFLAGS  = $(CXXSTANDARD)
CXXFLAGS += $(COFLAGS)
CXXFLAGS += $(CWFLAGS)
CXXFLAGS += $(CAFLAGS)
CXXFLAGS += $(CIFLAGS)

ASFLAGS  = $(COFLAGS)
ASFLAGS += $(CAFLAGS)
ASFLAGS += -Wa,-g$(DEBUG),--listing-cont-lines=100



# Library Options
#----------------
# FIXME: generalize
# Minimalistic printf version
PRINTF_LIB_MIN = -Wl,-u,vfprintf -lprintf_min

# Floating point printf version (requires MATH_LIB = -lm below)
PRINTF_LIB_FLOAT = -Wl,-u,vfprintf -lprintf_flt

# If this is left blank, then it will use the Standard printf version.
PRINTF_LIB =
#PRINTF_LIB = $(PRINTF_LIB_MIN)
#PRINTF_LIB = $(PRINTF_LIB_FLOAT)


# Minimalistic scanf version
SCANF_LIB_MIN = -Wl,-u,vfscanf -lscanf_min

# Floating point + %[ scanf version (requires MATH_LIB = -lm below)
SCANF_LIB_FLOAT = -Wl,-u,vfscanf -lscanf_flt

# If this is left blank, then it will use the Standard scanf version.
SCANF_LIB =
#SCANF_LIB = $(SCANF_LIB_MIN)
#SCANF_LIB = $(SCANF_LIB_FLOAT)


MATH_LIB = -lm



# External Memory Options
#------------------------

# 64 KB of external RAM, starting after internal RAM (ATmega128!),
# used for variables (.data/.bss) and heap (malloc()).
#EXTMEMOPTS = -Wl,-Tdata=0x801100,--defsym=__heap_end=0x80ffff

# 64 KB of external RAM, starting after internal RAM (ATmega128!),
# only used for heap (malloc()).
#EXTMEMOPTS = -Wl,--section-start,.data=0x801100,--defsym=__heap_end=0x80ffff

EXTMEMOPTS =



# Linker Options
#---------------
#  -Wl,...:     tell GCC to pass this to linker.
#    -Map:      create map file
#    --cref:    add cross reference to  map file
LDFLAGS += -Wl,-Map=$(TARGET).map,--cref
LDFLAGS += -Wl,--relax
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,--print-gc-sections # from sooda
LDFLAGS += $(COFLAGS)
LDFLAGS += -fwhole-program      # from sooda
#LDFLAGS += -combine            # from sooda
LDFLAGS += $(EXTMEMOPTS)
LDFLAGS += $(patsubst %,-L%,$(EXTRALIBDIRS))
#LDFLAGS += -T linker_script.x

# This is seperate variable as some libraries need to be after object files
LDLIBS += $(PRINTF_LIB) $(SCANF_LIB) $(MATH_LIB)



# Commons
# -------
# Define all object files.
OBJ = $(patsubst %,$(BUILDDIR)/%.o,$(basename $(SRC)))

# Commands
#CC = from environment.mk
CXX = $(CC) -x c++
ASM = $(CC) -x assembler-with-cpp

COMPILE.c = $(CC) $(TARGET_ARCH) $(CFLAGS) $(CPPFLAGS)
COMPILE.cc = $(CXX) $(TARGET_ARCH) $(CXXFLAGS) $(CPPFLAGS)
COMPILE.S = $(ASM) $(TARGET_ARCH) $(ASFLAGS) $(CPPFLAGS:%00UL=%00)

LINK.o = $(CC) $(TARGET_ARCH) $(LDFLAGS) $(CPPFLAGS)




#   Stage: post-variables
else ifeq ($(yaamake_stage),p)
# ============================




# Handle source outside of CWD using VPATH
#  remove (../)+ pattern from file and add those patterns as VPATH paths
#  NOTE: this will not work in cases whre SRC = ../main.cpp main.cpp
#        as resulting SRC will be: main.cpp main.cpp
#  There is no good way to handle ../ prefixed SRCs. This is best we can do...
#  NOTE: you still can damn your self if you use paths like foobar/../../baz.cpp
override SRC := $(foreach src,$(SRC),$(call drop_leading_cwd,$(src)))
override _SRC_relative := $(filter ../%,$(SRC))
override _SRC_relative_files := $(foreach src,$(_SRC_relative),$(call drop_leading_parent,$(src)))
override _SRC_relative_vpath := $(foreach src,$(_SRC_relative),$(patsubst %$(call drop_leading_parent,$(src)),%,$(src)))
override _SRC_absolute := $(patsubst /%,%,$(filter /%,$(SRC)))
override SRC := $(filter-out /% ../%,$(SRC)) $(_SRC_relative_files) $(_SRC_absolute)

# Validate filenames in SRC
ifneq ($(call contains_duplicates,$(SRC)),)
$(error Your SRC files include some duplicate filenames: $(SRC))
endif

# Build VPATH from one provided so far and ones from above
# TODO: check that path exists (any need for that?)
override VPATH := $(call remove_duplicates,$(VPATH) $(_SRC_relative_vpath) $(if $(_SRC_absolute),/,))






#   Stage: targets
else ifeq ($(yaamake_stage),t)
# ============================




# ========================
# targets for user to call
# ========================

.PHONY: build_help
build_help:
	$(HELP_TITTLE) compiling
	$(HELP_DESC) "This section is used to compile your sourecode into bytecode"
	$(HELP_ATTRS)
	$(HELP_ATTR) SRC "list of sourcefiles [first of main.* and TARGET.*]"
	$(HELP_ATTR) TARGET "target filename prefix, seults TARGET.hex etc. [current directory name]"
	$(HELP_ATTR) EXTRAINCDIRS "Any extra directories to look for include files."
	$(HELP_ATTR) EXTRALIBDIRS "Any extra directories to look for libraries."
	$(HELP_ATTR) BUILDDIR "Directory for containing build time files (objects, etc). [CACHEDIR/build]"
	$(HELP_TARGETS)
	$(HELP_TARGET) build "build project files"
	$(HELP_TARGET) clean "clean build files"


# Target: build project
.PHONY: build
build: begin gccversion sizebefore elf lss sym sizeafter end



# Target: clean project
.PHONY: clean clean_list
clean: begin clean_list end

clean_list:
	@echo
	@echo $(MSG_CLEANING)
	$(if $(TARGET),$(REMOVE) $(TARGET).hex,)
	$(if $(TARGET),$(REMOVE) $(TARGET).eep,)
	$(if $(TARGET),$(REMOVE) $(TARGET).cof,)
	$(if $(TARGET),$(REMOVE) $(TARGET).elf,)
	$(if $(TARGET),$(REMOVE) $(TARGET).map,)
	$(if $(TARGET),$(REMOVE) $(TARGET).sym,)
	$(if $(TARGET),$(REMOVE) $(TARGET).lss,)
	$(if $(OBJ),$(REMOVE) $(OBJ),)
	$(if $(OBJ),$(REMOVE) $(OBJ:%.o=%.lst),)
	$(if $(SRC),$(REMOVE) $(patsubst %,$(BUILDDIR)/%.dep,$(SRC)),)
	$(if $(SRC),$(REMOVE) $(addsuffix .s,$(basename $(SRC))),)
	$(if $(SRC),$(REMOVE) $(addsuffix .d,$(basename $(SRC))),)
	$(if $(SRC),$(REMOVE) $(addsuffix .i,$(basename $(SRC))),)
	$(if $(SRC),$(REMOVE) $(addsuffix .m,$(basename $(SRC))),)



# Type targets
.PHONY: elf hex eep lss sym lib
elf: $(TARGET).elf
hex: $(TARGET).hex
eep: $(TARGET).eep
lss: $(TARGET).lss
sym: $(TARGET).sym
lib: lib$(TARGET).a



# Display size of file.
# HEXSIZE = $(SIZE) --target=$(FORMAT) $(TARGET).hex
ELFSIZE = $(SIZE) --mcu=$(MCU) --format=avr $(TARGET).elf

.PHONY: sizebefore sizeafter
sizebefore:
	$(call require,TARGET)
	@if test -f $(TARGET).elf; then \
		echo; \
		echo $(MSG_SIZE_BEFORE); \
		$(ELFSIZE); \
		2>/dev/null; \
		echo; \
	fi

sizeafter:
	$(call require,TARGET)
	@if test -f $(TARGET).elf; then \
		echo; \
		echo $(MSG_SIZE_AFTER); \
		$(ELFSIZE); 2>/dev/null; \
		echo; \
	fi



# Display compiler version information.
.PHONY: gccversion
gccversion :
	@$(CC) --version



# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
COFFCONVERT = $(OBJCOPY) --debugging
COFFCONVERT += --change-section-address .data-0x800000
COFFCONVERT += --change-section-address .bss-0x800000
COFFCONVERT += --change-section-address .noinit-0x800000
COFFCONVERT += --change-section-address .eeprom-0x810000

.PHONY: coff extcoff
coff: $(TARGET).elf
	$(call require,TARGET)
	@echo
	@echo $(MSG_COFF) $(TARGET).cof
	$(COFFCONVERT) -O coff-avr $< $(TARGET).cof

extcoff: $(TARGET).elf
	$(call require,TARGET)
	@echo
	@echo $(MSG_EXTENDED_COFF) $(TARGET).cof
	$(COFFCONVERT) -O coff-ext-avr $< $(TARGET).cof




# -----------------------------------
# Generic pattern targets for actions
# -----------------------------------


# Create final output files (.hex, .eep) from ELF output file.
%.hex: %.elf
	@echo
	@echo $(MSG_FLASH) $@
	$(OBJCOPY) -O $(FORMAT) -R .eeprom -R .fuse -R .lock -R .signature $< $@

%.eep: %.elf
	@echo
	@echo $(MSG_EEPROM) $@
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 --no-change-warnings -O $(FORMAT) $< $@ || exit 0



# Create extended listing file from ELF output file.
%.lss: %.elf
	@echo
	@echo $(MSG_EXTENDED_LISTING) $@
	$(OBJDUMP) -h -S -z $< > $@



# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo
	@echo $(MSG_SYMBOL_TABLE) $@
	$(NM) -n $< > $@



# Create library from object files.
.SECONDARY : $(TARGET).a
%.a: $(OBJ)
	$(call require,SRC,$(SRC_ERROR_MSG))
	$(call require,MCU OBJ TARGET)
	@echo
	@echo $(MSG_CREATING_LIBRARY) $@
	$(AR) $@ $(OBJ)


# Link: create ELF output file from object files.
.SECONDARY : $(TARGET).elf
%.elf: $(OBJ)
	$(call require,SRC,$(SRC_ERROR_MSG))
	$(call require,MCU OBJ TARGET)
	@echo
	@echo $(MSG_LINKING) $@
# LDLIBS needs to be after object files for some library stuff to work correctly
	$(LINK.o) -o $@ $^ $(LDLIBS)


# Compile: create object files from C, C++ and assembly source files.
.PRECIOUS : $(OBJ)
$(OBJ) : $(firstword $(MAKEFILE_LIST))
override BUILD_REQUIRE = $(call require,MCU F_CPU)


$(BUILDDIR)/%.o : %.c
	$(BUILD_REQUIRE)
	@echo
	@echo $(MSG_COMPILING) $<
	@mkdir -p $(@D)
	$(COMPILE.c) -c -o $@ $<

$(BUILDDIR)/%.o : %.cpp
	$(BUILD_REQUIRE)
	@echo
	@echo $(MSG_COMPILING_CPP) $<
	@mkdir -p $(@D)
	$(COMPILE.cc) -c -o $@ $<

$(BUILDDIR)/%.o : %.cc
	$(BUILD_REQUIRE)
	@echo
	@echo $(MSG_COMPILING_CPP) $<
	@mkdir -p $(@D)
	$(COMPILE.cc) -c -o $@ $<

$(BUILDDIR)/%.o : %.S
	$(BUILD_REQUIRE)
	@echo
	@echo $(MSG_ASSEMBLING) $<
	@mkdir -p $(@D)
	$(COMPILE.S) -c -o $@ $<


# Compile: create assembler files from C and C++ source files.
%.s : %.c
	$(BUILD_REQUIRE)
	$(COMPILE.c) -S -o $@ $<

%.s : %.cpp
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -S -o $@ $<

%.s : %.cc
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -S -o $@ $<


# Create preprocessed source for use in sending a bug report.
%.i : %.c
	$(BUILD_REQUIRE)
	$(COMPILE.c) -E -o $@ $<

%.i : %.cpp
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -E -o $@ $<

%.i : %.cc
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -E -o $@ $<


# Create list of defined macros
%.m : %.c
	$(BUILD_REQUIRE)
	$(COMPILE.c) -dM -E -o $@ $<

%.m : %.cpp
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -dM -E -o $@ $<

%.m : %.cc
	$(BUILD_REQUIRE)
	$(COMPILE.cc) -dM -E -o $@ $<





#======================================

# Include the dependency files.
-include $(shell $(FIND) $(BUILDDIR) -type f -iname '*.dep' 2>/dev/null)



# Stages end
endif
