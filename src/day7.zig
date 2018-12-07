const std = @import("std");
const fun = @import("fun");

const debug = std.debug;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
const os = std.os;

const scan = fun.scan.scan;

pub fn main() !void {
    const stdin = &(try io.getStdIn()).inStream().stream;
    const stdout = &(try io.getStdOut()).outStream().stream;
    var ps = io.PeekStream(1, os.File.InStream.Error).init(stdin);

    var direct_allocator = heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const dependencies = try readDependencies(allocator, &ps);

    const build_order = try buildOrder(allocator, dependencies);
    try stdout.print("{}\n", build_order);
}

fn readDependencies(allocator: *mem.Allocator, ps: var) ![]Dependency {
    var dependencies = std.ArrayList(Dependency).init(allocator);
    defer dependencies.deinit();

    while (readDependency(ps)) |dp| {
        try dependencies.append(dp);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return dependencies.toOwnedSlice();
}

fn readDependency(ps: var) !Dependency {
    _ = try scan(ps, "Step ", struct {});
    const depends_on = try ps.stream.readByte();
    _ = try scan(ps, " must be finished before step ", struct {});
    const step = try ps.stream.readByte();
    _ = try scan(ps, " can begin.\n", struct {});

    return Dependency{
        .step = step,
        .depends_on = depends_on,
    };
}

const Dependency = struct {
    step: u8,
    depends_on: u8,
};

fn buildOrder(allocator: *mem.Allocator, dependencies: []const Dependency) ![]u8 {
    var arena_state = heap.ArenaAllocator.init(allocator);
    const arena = &arena_state.allocator;
    defer arena_state.deinit();

    var res = std.ArrayList(u8).init(allocator);
    defer res.deinit();

    const Deps = std.AutoHashMap(u8, void);
    var dep_map = std.AutoHashMap(u8, Deps).init(allocator);
    for (dependencies) |dep| {
        const kv = try dep_map.getOrPutValue(dep.step, Deps.init(allocator));
        _ = try dep_map.getOrPutValue(dep.depends_on, Deps.init(allocator));
        _ = try kv.value.put(dep.depends_on, {});
    }

    while (dep_map.count() != 0) {
        var iter = dep_map.iterator();
        var build = loop: while (iter.next()) |kv| {
            if (kv.value.count() == 0)
                break :loop kv.key;
        } else {
            return error.CouldNotBuild;
        };

        while (iter.next()) |kv| {
            if (kv.value.count() == 0 and kv.key < build)
                build = kv.key;
        }

        _ = dep_map.remove(build) orelse unreachable;
        try res.append(build);

        iter = dep_map.iterator();
        while (iter.next()) |kv| {
            _ = kv.value.remove(build);
        }
    }

    return res.toOwnedSlice();
}
