#!/bin/bash

# Path to raw kernel binary
KERNEL_BIN="zig-out/bin/kernel"
UIMAGE_OUT="zig-out/bin/aixos.uImage"

# Load and entry addresses
LOAD_ADDR="0x8000"
ENTRY_ADDR="0x8000"

# Ensure mkimage is available
if ! command -v mkimage &> /dev/null; then
    echo "Error: mkimage not found. Please install u-boot-tools."
    exit 1
fi

# Create uImage
echo "[+] Generating U-Boot uImage..."
mkimage -A arm -O linux -T kernel -C none \
  -a $LOAD_ADDR -e $ENTRY_ADDR \
  -n "AIxOS nanokernel" \
  -d "$KERNEL_BIN" "$UIMAGE_OUT"

echo "[+] uImage created at $UIMAGE_OUT"
