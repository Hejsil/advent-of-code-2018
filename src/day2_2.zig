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

    const match = try findMatch(allocator, stdin);
    defer allocator.free(match);
    try stdout.print("{}\n", match);
}

fn findMatch(allocator: *mem.Allocator, in_stream: var) ![]u8 {
    var line_buf = try std.Buffer.initSize(allocator, 0);
    defer line_buf.deinit();

    var all = std.ArrayList([]const u8).init(allocator);
    defer all.deinit();

    while (true) {
        try in_stream.readUntilDelimiterBuffer(&line_buf, '\n', 10000);
        const line = mem.trimRight(u8, line_buf.toSlice(), "\r\n");

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
}
