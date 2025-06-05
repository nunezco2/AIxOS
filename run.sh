#!/bin/bash
qemu-system-arm \
  -M versatilepb \
  -m 128M \
  -nographic \
  -serial mon:stdio \
  -kernel zig-out/bin/kernel \
  "$@"
