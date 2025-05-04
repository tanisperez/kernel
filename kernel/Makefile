# Nuke built-in rules and variables.
MAKEFLAGS += -rR

BUILD_FOLDER := bin
KERNEL_FILE := kernel

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
	-T linker-x86_64.ld

# Use "find" to glob all *.c, *.S, and *.asm files in the tree and obtain the
# object and header dependency file names.
override SRCFILES := $(shell cd src && find -L * -type f | LC_ALL=C sort)
override CFILES := $(filter %.c,$(SRCFILES))
override C3FILES := $(filter %.c3,$(SRCFILES))
override OBJ := $(addprefix $(BUILD_FOLDER)/,$(C3FILES:.c3=.c3.o) $(CFILES:.c=.c.o))
override HEADER_DEPS := $(addprefix $(BUILD_FOLDER)/,$(CFILES:.c=.c.d))

# Default target. This must come first, before header dependencies.
all: $(BUILD_FOLDER)/$(KERNEL_FILE)

# Include header dependencies.
-include $(HEADER_DEPS)

# Link rules for the final executable.
$(BUILD_FOLDER)/$(KERNEL_FILE): Makefile linker-x86_64.ld $(OBJ)
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJ) -o $@

# Compilation rules for *.c3 files.
$(BUILD_FOLDER)/%.c3.o: src/%.c3 Makefile
	mkdir -p "$$(dirname $@)"
	c3c compile-only --single-module=yes --link-libc=no --use-stdlib=no --emit-stdlib=no $< -o $@

# Compilation rules for *.c files.
$(BUILD_FOLDER)/%.c.o: src/%.c Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_FOLDER)
