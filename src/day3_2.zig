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
    var ps = io.PeekStream(1, os.File.InStream.Error).init(stdin);

    var direct_allocator = heap.DirectAllocator.init();
    var arena = heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer direct_allocator.deinit();
    defer arena.deinit();

    const allocator = &arena.allocator;
    var claims = std.ArrayList(Claim).init(allocator);

    while (scan(&ps, "#{} @ {},{}: {}x{}\n", Claim)) |claim| {
        try claims.append(claim);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    outer: for (claims.toSlice()) |a, i| {
        for (claims.toSlice()) |b, j| {
            if (i == j)
                continue;
            if (a.intersects(b))
                continue :outer;
        }

        try stdout.print("{}\n", a.id);
    }
}

const Claim = struct {
    id: usize,
    x: usize,
    y: usize,
    width: usize,
    height: usize,

    fn intersects(a: Claim, b: Claim) bool {
        const top_left = Point{
            .x = math.max(a.x, b.x),
            .y = math.max(a.y, b.y),
        };
        const bot_right = Point{
            .x = math.min(a.x + a.width, b.x + b.width),
            .y = math.min(a.y + a.height, b.y + b.height),
        };

        return top_left.x < bot_right.x and top_left.y < bot_right.y;
    }
};

const Point = struct {
    x: usize,
    y: usize,
};
