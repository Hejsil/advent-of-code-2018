const fun = @import("fun");
const std = @import("std");

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

    var direct_allocator = heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const lines = try readLines(allocator, stdin);
    defer {
        for (lines) |line|
            allocator.free(line);
        allocator.free(lines);
    }

    try stdout.print("{}\n", checksum(lines));

    const match = try findMatch(allocator, lines);
    defer allocator.free(match);
    try stdout.print("{}\n", match);
}

fn readLines(allocator: *mem.Allocator, in_stream: var) ![][]u8 {
    var lines = std.ArrayList([]u8).init(allocator);
    defer {
        for (lines.toSlice()) |line|
            allocator.free(line);
        lines.deinit();
    }

    while (in_stream.readUntilDelimiterAlloc(allocator, '\n', 10000)) |line| {
        try lines.append(line);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return lines.toOwnedSlice();
}

fn checksum(lines: []const []const u8) u64 {
    var counts = []u64{0} ** (math.maxInt(u8) + 1);

    for (lines) |line| {
        var add = []u1{0} ** (math.maxInt(u8) + 1);
        var letters = []u64{0} ** (math.maxInt(u8) + 1);

        for (line) |c|
            letters[c] += 1;
        for (letters) |num|
            add[num] = 1;
        for (add) |num, i|
            counts[i] += num;
    }

    return counts[2] * counts[3];
}

fn findMatch(allocator: *mem.Allocator, lines: []const []const u8) ![]u8 {
    var all = std.ArrayList([]const u8).init(allocator);
    defer all.deinit();

    for (lines) |line| {
        for (all.toSlice()) |str| {
            if (str.len != line.len)
                continue;

            var diff: usize = 0;
            for (str) |c, i|
                diff += @boolToInt(c != line[i]);

            if (diff != 1)
                continue;

            var res = try allocator.alloc(u8, line.len - 1);
            var res_ptr = res.ptr;
            for (str) |c, i| {
                if (c != line[i])
                    continue;

                res_ptr.* = c;
                res_ptr += 1;
            }

            debug.assert(res.ptr + res.len == res_ptr);
            return res;
        }

        try all.append(try mem.dupe(allocator, u8, line));
    }

    return error.NoMatch;
}
