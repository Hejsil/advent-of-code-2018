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

    try stdout.print("{}\n", try firstDupSum(allocator, &ps));
}

fn firstDupSum(allocator: *mem.Allocator, ps: var) !i64 {
    var map = std.AutoHashMap(i64, void).init(allocator);
    defer map.deinit();

    var sum: i64 = 0;
    while (true) {
        const line = try scan(ps, "{}\n", struct {
            i: i64,
        });
        sum += line.i;

        const m_entry = try map.put(sum, {});
        if (m_entry) |entry|
            return sum;
    }
}
