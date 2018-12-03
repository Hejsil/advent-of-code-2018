const fun = @import("fun");
const std = @import("std");

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

    try stdout.print("{}\n", try checksum(allocator, stdin));
}

fn checksum(allocator: *mem.Allocator, in_stream: var) !u64 {
    var counts = []u64{0} ** (math.maxInt(u8) + 1);
    var line_buf = try std.Buffer.initSize(allocator, 0);
    defer line_buf.deinit();

    while (in_stream.readUntilDelimiterBuffer(&line_buf, '\n', 10000)) {
        const line = mem.trimRight(u8, line_buf.toSlice(), "\r\n");
        var add = []u1{0} ** (math.maxInt(u8) + 1);
        var letters = []u64{0} ** (math.maxInt(u8) + 1);

        for (line) |c|
            letters[c] += 1;
        for (letters) |num|
            add[num] = 1;
        for (add) |num, i|
            counts[i] += num;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return counts[2] * counts[3];
}
