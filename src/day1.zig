const fun = @import("fun");
const std = @import("std");

const heap = std.heap;
const io = std.io;
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

    const ints = try readInts(allocator, &ps);

    try stdout.print("{}\n", sum(i64, ints));
    try stdout.print("{}\n", try firstDupSum(allocator, i64, ints));
}

fn readInts(allocator: *mem.Allocator, ps: var) ![]i64 {
    var res = std.ArrayList(i64).init(allocator);
    defer res.deinit();

    while (scan(ps, "{}\n", struct {
        i: i64,
    })) |line| {
        try res.append(line.i);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return res.toOwnedSlice();
}

fn sum(comptime T: type, slice: []const T) i64 {
    var res: i64 = 0;
    for (slice) |i|
        res += i;

    return res;
}

fn firstDupSum(allocator: *mem.Allocator, comptime T: type, slice: []const T) !i64 {
    var map = std.AutoHashMap(i64, void).init(allocator);
    defer map.deinit();

    var res: i64 = 0;
    while (true) {
        for (slice) |i| {
            res += i;

            if (try map.put(res, {})) |_|
                return res;
        }
    }
}
