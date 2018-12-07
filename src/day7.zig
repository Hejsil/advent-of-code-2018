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
    try stdout.print("{}\n", try buildSpeed(allocator, 5, 61 - 'A', dependencies));
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

test "buildSpeed" {
    var direct_allocator = heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const speed = try buildSpeed(allocator, 2, 1 - 'A', []Dependency{
        Dependency{ .step = 'A', .depends_on = 'C' },
        Dependency{ .step = 'F', .depends_on = 'C' },
        Dependency{ .step = 'B', .depends_on = 'A' },
        Dependency{ .step = 'D', .depends_on = 'A' },
        Dependency{ .step = 'E', .depends_on = 'B' },
        Dependency{ .step = 'E', .depends_on = 'D' },
        Dependency{ .step = 'E', .depends_on = 'F' },
    });
    debug.assert(speed == 15);
}

fn buildSpeed(allocator: *mem.Allocator, workers: usize, duration: isize, dependencies: []const Dependency) !isize {
    var arena_state = heap.ArenaAllocator.init(allocator);
    const arena = &arena_state.allocator;
    defer arena_state.deinit();

    const Work = struct {
        work: u8,
        done: isize,

        fn lessThan(a: @This(), b: @This()) bool {
            return a.done < b.done;
        }
    };

    var work_stack = std.ArrayList(Work).init(arena);
    try work_stack.ensureCapacity(workers + 1);

    var next_work = std.ArrayList(u8).init(arena);
    try next_work.ensureCapacity(workers + 1);

    const Deps = std.AutoHashMap(u8, void);
    var dep_map = std.AutoHashMap(u8, Deps).init(allocator);
    for (dependencies) |dep| {
        const kv = try dep_map.getOrPutValue(dep.step, Deps.init(allocator));
        _ = try dep_map.getOrPutValue(dep.depends_on, Deps.init(allocator));
        _ = try kv.value.put(dep.depends_on, {});
    }

    var res: isize = 0;
    while (dep_map.count() != 0 or work_stack.len != 0) {
        var iter = dep_map.iterator();
        while (iter.next()) |kv| {
            if (kv.value.count() != 0)
                continue;

            next_work.append(kv.key) catch unreachable;
            if (next_work.len > (workers - work_stack.len)) {
                std.sort.sort(u8, next_work.toSlice(), lessThan(u8));
                _ = next_work.pop();
            }
        }

        for (next_work.toSlice()) |work| {
            _ = dep_map.remove(work) orelse unreachable;
            work_stack.append(Work{
                .work = work,
                .done = res + duration + @intCast(isize, work),
            }) catch unreachable;
        }
        next_work.resize(0) catch unreachable;

        const time = min(Work, work_stack.toSlice(), Work.lessThan) orelse return error.CouldNotBuild;
        res += (time.done - res);

        var i: usize = 0;
        while (i < work_stack.len) {
            const work = &work_stack.toSlice()[i];
            if (work.done == res) {
                iter = dep_map.iterator();
                while (iter.next()) |kv| {
                    _ = kv.value.remove(work.work);
                }

                work.* = work_stack.pop();
            } else {
                i += 1;
            }
        }
    }

    return res;
}

fn min(comptime T: type, slice: []const T, lt: fn (T, T) bool) ?T {
    if (slice.len == 0)
        return null;

    var res = slice[0];
    for (slice[0..]) |item| {
        if (lt(item, res))
            res = item;
    }

    return res;
}

fn lessThan(comptime T: type) fn (T, T) bool {
    return struct {
        fn lessThan(a: T, b: T) bool {
            return a < b;
        }
    }.lessThan;
}
