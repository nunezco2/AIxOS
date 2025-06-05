const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .arm,
            .os_tag = .freestanding,
            .abi = .eabi,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm926ej_s },
        },
    });

    // Bootloader object
    const boot_obj = b.addObject(.{
        .name = "bootloader",
        .target = target,
        .optimize = optimize,
    });
    boot_obj.addAssemblyFile("bootloader/main.s");

    // Kernel executable
    const kernel = b.addExecutable(.{
        .name = "kernel",
        .target = target,
        .optimize = optimize,
    });

    kernel.setLinkerScriptPath(.{ .path = "linker.ld" });
    kernel.linkSystemLibrary("c");

    kernel.addAssemblyFile("bootloader/main.s");

    kernel.addIncludePath(.{ .path = "kernel" });
    kernel.addIncludePath(.{ .path = "shell" });
    kernel.addIncludePath(.{ .path = "ai-vm" });
    kernel.addIncludePath(.{ .path = "reflexivity" });
    kernel.addIncludePath(.{ .path = "sandbox" });
    kernel.addIncludePath(.{ .path = "dist" });

    kernel.addCSourceFiles(.{
        .files = &[_][]const u8{
            "kernel/core/scheduler.zig",
            "kernel/mm/mmu.zig",
            "kernel/syscall/syscalls.zig",
            "shell/main.zig",
            "ai-vm/vm.zig",
            "reflexivity/engine.zig",
            "sandbox/container.zig",
            "dist/peer.zig",
        },
        .flags = &[_][]const u8{},
    });

    // Main step
    const install = b.installArtifact(kernel);

    // Run via QEMU
    const run = b.addRunArtifact(kernel);
    run.step.dependOn(&install.step);
    run.addArgs(&[_][]const u8{
        "-M",                 "versatilepb",
        "-m",                 "128M",
        "-nographic",         "-serial",
        "stdio",              "-kernel",
        "zig-out/bin/kernel",
    });
    run.setExecCmd("qemu-system-arm");

    b.step("run", "Run in QEMU").dependOn(&run.step);

    // Testing step
    const test_kernel = b.addTest(.{
        .name = "kernel-tests",
        .target = target,
        .optimize = optimize,
    });
    test_kernel.addIncludePath(.{ .path = "tests" });
    test_kernel.addTestSourceFile("tests/test_kernel.zig");
    b.step("test", "Run unit tests").dependOn(&test_kernel.step);
}
