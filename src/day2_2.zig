const std = @import("std");

const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdin = &(try io.getStdIn()).inStream().stream;
    const stdout = &(try io.getStdOut()).outStream().stream;

    var direct_allocator = heap.DirectAllocator.init();
    var arena = heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer direct_allocator.deinit();
    defer arena.deinit();

    const allocator = &arena.allocator;

    var running = true;
    var line_buf = try std.Buffer.initSize(allocator, 0);
    defer line_buf.deinit();

    var all = std.ArrayList([]const u8).init(allocator);
    while (running) {
        stdin.readUntilDelimiterBuffer(&line_buf, '\n', 10000) catch |err| switch (err) {
            error.EndOfStream => running = false,
            else => return err,
        };
        const line = mem.trimRight(u8, line_buf.toSlice(), "\r\n");
        if (line.len == 0)
            continue;

        for (all.toSlice()) |str| {
            if (str.len != line.len)
                continue;

            var diff: usize = 0;
            for (str) |c, i|
                diff += @boolToInt(c != line[i]);

            if (diff == 1) {
                for (str) |c, i| {
                    if (c == line[i])
                        try stdout.print("{c}", c);
                }
                try stdout.print("\n");
                return;
            }
        }

        try all.append(try mem.dupe(allocator, u8, line));
    }

    return error.FoundNoMatch;
}
