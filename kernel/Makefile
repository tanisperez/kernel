# Nuke built-in rules and variables.
MAKEFLAGS += -rR

override OUTPUT := kernel

# Target architecture to build for. Default to x86_64.
ARCH := x86_64

# User controllable C compiler command.
CC := cc

# User controllable C flags.
CFLAGS := -g -O2 -pipe \
	-Wall \
	-Wextra \
	-std=gnu11 \
	-nostdinc \
	-ffreestanding \
	-fno-stack-protector \
	-fno-stack-check \
	-fno-PIC \
	-ffunction-sections \
	-fdata-sections \
	-m64 \
	-march=x86-64 \
	-mno-80387 \
	-mno-mmx \
	-mno-sse \
	-mno-sse2 \
	-mno-red-zone \
	-mcmodel=kernel

# User controllable C preprocessor flags. We set none by default.
CPPFLAGS := \
	-I src \
	-isystem src/freestnd-c-hdrs \
	$(CPPFLAGS) \
	-DLIMINE_API_REVISION=3 \
	-MMD \
	-MP

# User controllable linker flags. We set none by default.
LDFLAGS := -Wl,-m,elf_x86_64 \
	-Wl,--build-id=none \
	-nostdlib \
	-static \
	-z max-page-size=0x1000 \
	-Wl,--gc-sections \
	-T linker-$(ARCH).ld

# Use "find" to glob all *.c, *.S, and *.asm files in the tree and obtain the
# object and header dependency file names.
override SRCFILES := $(shell cd src && find -L * -type f | LC_ALL=C sort)
override CFILES := $(filter %.c,$(SRCFILES))
override C3FILES := $(filter %.c3,$(SRCFILES))
override OBJ := $(addprefix obj-$(ARCH)/,$(C3FILES:.c3=.c3.o) $(CFILES:.c=.c.o))
override HEADER_DEPS := $(addprefix obj-$(ARCH)/,$(CFILES:.c=.c.d))

# Default target. This must come first, before header dependencies.
.PHONY: all
all: bin-$(ARCH)/$(OUTPUT)

# Include header dependencies.
-include $(HEADER_DEPS)

# Link rules for the final executable.
bin-$(ARCH)/$(OUTPUT): Makefile linker-$(ARCH).ld $(OBJ)
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJ) -o $@

## TODO: Cambiar el Makefile para usar sólo un comando c3c que compile todo

# Compilation rules for *.c3 files.
obj-$(ARCH)/%.c3.o: src/%.c3 Makefile
	mkdir -p "$$(dirname $@)"
	c3c compile-only --single-module=yes --link-libc=no --use-stdlib=no --emit-stdlib=no $< -o $@

# Compilation rules for *.c files.
obj-$(ARCH)/%.c.o: src/%.c Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# Remove object files and the final executable.
.PHONY: clean
clean:
	rm -rf bin-$(ARCH) obj-$(ARCH)
