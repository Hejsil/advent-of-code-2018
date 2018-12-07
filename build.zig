const std = @import("std");

const debug = std.debug;
const mem = std.mem;
const os = std.os;
const path = os.path;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const src = "src";
    for ([]void{{}} ** 25) |_, i| {
        const day = b.fmt("day{}", i + 1);
        const file = b.fmt("{}{c}{}.zig", src, u8(path.sep), day);
        const real = path.realAlloc(b.allocator, file) catch continue;

        const exe = b.addExecutable(day, real);
        exe.setBuildMode(mode);
        exe.addPackagePath("fun", "lib/fun-with-zig/index.zig");

        const build_step = b.step(day, "");
        build_step.dependOn(&exe.step);
        b.default_step.dependOn(build_step);
    }
}
