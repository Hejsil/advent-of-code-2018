const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdin = &(try io.getStdIn()).inStream().stream;
    const stdout = &(try io.getStdOut()).outStream().stream;

    var direct_allocator = heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const polymer = mem.trimRight(u8, try stdin.readUntilDelimiterAlloc(allocator, '\n', 100000), "\r\n");
    defer allocator.free(polymer);

    const reacted_polymer = try react(allocator, polymer);
    try stdout.print("{}\n", reacted_polymer.len);

    var best: usize = math.maxInt(usize);
    for ([]void{{}} ** ('z' - 'a')) |_, i| {
        const c = @intCast(u8, i + 'a');

        const filtered = try filter(allocator, c, polymer);
        defer allocator.free(filtered);

        const reacted_filtered = try react(allocator, filtered);
        defer allocator.free(reacted_filtered);

        best = math.min(best, reacted_filtered.len);
    }

    try stdout.print("{}\n", best);
}

fn react(allocator: *mem.Allocator, polymer: []const u8) ![]u8 {
    var res = std.ArrayList(u8).init(allocator);
    errdefer res.deinit();

    for (polymer) |unit| {
        if (!isAlpha(unit))
            return error.InvalidPolymer;

        try res.append(unit);
        while (true) {
            const curr = res.toSliceConst();
            if (curr.len < 2)
                break;

            const a = res.pop();
            const b = res.pop();
            if (!canReact(a, b)) {
                res.append(b) catch unreachable;
                res.append(a) catch unreachable;
                break;
            }
        }
    }

    return res.toOwnedSlice();
}

fn filter(allocator: *mem.Allocator, unit: u8, polymer: []const u8) ![]u8 {
    const norm_unit = toLower(unit);
    var res = std.ArrayList(u8).init(allocator);
    errdefer res.deinit();

    for (polymer) |c| {
        if (toLower(c) != norm_unit)
            try res.append(c);
    }

    return res.toOwnedSlice();
}

fn isAlpha(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z' => true,
        else => false,
    };
}

fn toLower(c: u8) u8 {
    return switch (c) {
        'A'...'Z' => c + ('a' - 'A'),
        else => c,
    };
}

fn canReact(a: u8, b: u8) bool {
    const low = math.min(a, b);
    const high = math.max(a, b);
    return u16(low) + ('a' - 'A') == high;
}
