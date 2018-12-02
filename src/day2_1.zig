const std = @import("std");

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

    var running = true;
    var line_buf = try std.Buffer.initSize(allocator, 0);
    defer line_buf.deinit();

    var counts = []u8{0} ** math.maxInt(u8);
    while (running) {
        var add = []u8{0} ** math.maxInt(u8);
        var letters = []u8{0} ** math.maxInt(u8);

        stdin.readUntilDelimiterBuffer(&line_buf, '\n', 10000) catch |err| switch (err) {
            error.EndOfStream => running = false,
            else => return err,
        };
        const line = mem.trimRight(u8, line_buf.toSlice(), "\r\n");
        if (line.len == 0)
            continue;

        for (line) |c|
            letters[c] += 1;
        for (letters) |num|
            add[num] = 1;
        for (add) |num, i|
            counts[i] += num;
    }

    try stdout.print("{}\n", u64(counts[2]) * counts[3]);
}
