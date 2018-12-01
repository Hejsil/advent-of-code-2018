const std = @import("std");

const io = std.io;
const heap = std.heap;
const mem = std.mem;
const fmt = std.fmt;

pub fn main() !void {
    const stdin = &(try io.getStdIn()).inStream().stream;
    const stdout = &(try io.getStdOut()).outStream().stream;
    var direct_allocator = heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    var res: i64 = 0;
    var map = std.AutoHashMap(i64, void).init(allocator);
    var running = true;
    var line_buf = try std.Buffer.initSize(allocator, 0);
    defer line_buf.deinit();
    while (running) {
        stdin.readUntilDelimiterBuffer(&line_buf, '\n', 10000) catch |err| switch (err) {
            error.EndOfStream => running = false,
            else => return err,
        };
        const line = mem.trimRight(u8, line_buf.toSlice(), "\r\n");
        if (line.len == 0)
            continue;

        res += try fmt.parseInt(i64, line, 10);

        const m_entry = try map.put(res, {});
        if (m_entry) |entry|
            try stdout.print("{}\n", entry.key);

        line_buf.shrink(0);
    }

}
