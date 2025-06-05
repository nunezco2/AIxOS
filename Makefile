# Paths
BUILD_DIR := build
BOOT_DIR := bootloader
KERNEL_DIR := kernel
SHELL_DIR := shell
VM_DIR := ai-vm

# Tools
AS := arm-none-eabi-as
LD := arm-none-eabi-ld
OBJCOPY := arm-none-eabi-objcopy
ZIG := zig

# Targets
BOOT_OBJ := $(BUILD_DIR)/boot.o
BOOT_ELF := $(BUILD_DIR)/boot.elf
KERNEL_BIN := $(BUILD_DIR)/kernel.bin

# Entry symbol
ENTRY := _start

# Flags
ASFLAGS := -mcpu=arm926ej-s
LDFLAGS := -T linker.ld -nostdlib -static

# Default
all: bootloader kernel

# ----------------------------
# Bootloader (Assembly)
# ----------------------------

bootloader: $(BOOT_ELF)

$(BOOT_OBJ): $(BOOT_DIR)/main.s
	@mkdir -p $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(BOOT_ELF): $(BOOT_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

# ----------------------------
# Kernel & Shell (Zig)
# ----------------------------

kernel:
	$(ZIG) build-exe \
		--target=arm-linux-none-eabi \
		--cpu=arm926ej-s \
		--strip \
		--name kernel \
		--output-dir $(BUILD_DIR) \
		$(KERNEL_DIR)/core/scheduler.zig \
		$(KERNEL_DIR)/mm/mmu.zig \
		$(KERNEL_DIR)/syscall/syscalls.zig \
		$(SHELL_DIR)/main.zig \
		$(VM_DIR)/vm.zig \
		-reflexivity/engine.zig \
		-sandbox/container.zig \
		-dist/peer.zig

# ----------------------------
# Emulation
# ----------------------------

run-qemu:
	qemu-system-arm -M versatilepb -m 128M \
		-kernel $(BOOT_ELF) \
		-serial stdio -nographic

# ----------------------------
# Testing (Zig unit tests)
# ----------------------------

test:
	$(ZIG) test tests/test_kernel.zig

# ----------------------------
# Maintenance
# ----------------------------

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all bootloader kernel run-qemu test clean
