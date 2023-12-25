const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // === zig build (install) ===
    {
        const exe_options = b.addOptions();
        exe_options.addOption(bool, "use_gpa", b.option(bool, "use_gpa", "Use GeneralPurposeAllocator (good for debugging)") orelse (optimize == .Debug));
        exe_options.addOption(bool, "disable_anti_aliasing", b.option(bool, "disable_anti_aliasing", "Disable anti-aliasing") orelse false);

        const exe = b.addExecutable(.{
            .name = "raytracing-in-one-weekend",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.addModule("build_options", exe_options.createModule());

        b.installArtifact(exe);

        // === zig build run ===
        {
            const run_cmd = b.addRunArtifact(exe);

            run_cmd.step.dependOn(b.getInstallStep());

            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step("run", "Run the app");
            run_step.dependOn(&run_cmd.step);
        }
    }

    // === zig build test ===
    {
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
}
