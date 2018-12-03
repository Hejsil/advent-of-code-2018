const std = @import("std");

const os = std.os;
const path = os.path;
const mem = std.mem;

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();

    const src = "src";
    var dir = try os.Dir.open(b.allocator, src);
    while (try dir.next()) |entry| {
        const name = mem.split(entry.name, ".").next().?;
        const file = b.fmt("{}{c}{}", src, u8(path.sep), entry.name);
        const exe = b.addExecutable(name, file);
        exe.setBuildMode(mode);
        exe.addPackagePath("fun", "lib/fun-with-zig/index.zig");

        const build_step = b.step(name, b.fmt("Build {}", name));
        build_step.dependOn(&exe.step);
        b.default_step.dependOn(build_step);
    }
}
