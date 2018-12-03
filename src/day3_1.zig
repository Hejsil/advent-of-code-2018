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

    var fabric_width: usize = 0;
    var fabric_height: usize = 0;
    while (scan(&ps, "#{} @ {},{}: {}x{}\n", Claim)) |claim| {
        try claims.append(claim);
        fabric_width = math.max(fabric_width, claim.width + claim.x);
        fabric_height = math.max(fabric_height, claim.height + claim.y);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    const fabric = try allocator.alloc(usize, fabric_width * fabric_height);
    mem.set(usize, fabric, 0);
    for (claims.toSlice()) |claim| {
        var x: usize = claim.x;
        while (x < claim.width + claim.x) : (x += 1) {
            var y: usize = claim.y;
            while (y < claim.height + claim.y) : (y += 1) {
                fabric[x + (fabric_width * y)] += 1;
            }
        }
    }

    var res: usize = 0;
    for (fabric) |inche| {
        if (inche >= 2)
            res += 1;
    }
    try stdout.print("{}\n", res);
}

const Claim = struct {
    id: usize,
    x: usize,
    y: usize,
    width: usize,
    height: usize,
};
