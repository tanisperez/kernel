# Disable built-in rules and variables.
MAKEFLAGS += -rR

# Image name with the Kernel
IMAGE_NAME := kernel-x86_64

# Default user QEMU flags. These are appended to the QEMU command calls.
QEMUFLAGS := -m 2G

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
	-I src/include \
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

include scripts/dependencies.mk
include scripts/run.mk

# Use "find" to glob all *.c, *.S, and *.asm files in the tree and obtain the
# object and header dependency file names.
override SRCFILES := $(shell cd src && find -L * -type f | LC_ALL=C sort)
override CFILES := $(filter %.c,$(SRCFILES))
override C3FILES := $(filter %.c3,$(SRCFILES))
override OBJ := $(addprefix bin/,$(C3FILES:.c3=.c3.o) $(CFILES:.c=.c.o))
override HEADER_DEPS := $(addprefix bin/,$(CFILES:.c=.c.d))

# Link rules for the final executable.
bin/kernel: linker-x86_64.ld
	mkdir -p bin/
	mkdir -p bin/boot
	mkdir -p bin/cpu
	$(CC) $(CFLAGS) $(CPPFLAGS) -c src/boot/limine.c -o bin/boot/limine.c.o
	$(CC) $(CFLAGS) $(CPPFLAGS) -c src/cpu/system.c -o bin/cpu/system.c.o
	c3c compile-only --single-module=yes --link-libc=no --use-stdlib=no --emit-stdlib=no \
 		src/kmain.c3 \
 		src/types/types.c3 \
 		src/boot/limine.c3 \
 		src/cpu/system.c3 \
 		src/drivers/serial.c3 \
 		src/drivers/frame_buffer.c3 \
 		-o bin/kmain.o
	$(CC) $(CFLAGS) $(LDFLAGS) \
		bin/boot/limine.c.o \
		bin/cpu/system.c.o \
		bin/kmain.o \
		-o $@

all: $(IMAGE_NAME).iso

all-hdd: $(IMAGE_NAME).hdd

.PHONY: test
test:
	c3c compile-test test/types/types.c3

clean:
	rm -rf bin/ iso_root/ $(IMAGE_NAME).iso $(IMAGE_NAME).hdd

distclean:
	rm -rf bin/ iso_root/ *.iso *.hdd limine ovmf
