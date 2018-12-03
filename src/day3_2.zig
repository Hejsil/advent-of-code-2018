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
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const claims = try readClaims(allocator, &ps);
    defer allocator.free(claims);

    const claim = firstNoneIntersectingClaim(claims) orelse return error.NoPerfectClaim;
    try stdout.print("{}\n", claim.id);
}

fn readClaims(allocator: *mem.Allocator, ps: var) ![]Claim {
    var claims = std.ArrayList(Claim).init(allocator);
    defer claims.deinit();

    while (scan(ps, "#{} @ {},{}: {}x{}\n", Claim)) |claim| {
        try claims.append(claim);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return claims.toOwnedSlice();
}

fn firstNoneIntersectingClaim(claims: []const Claim) ?Claim {
    outer: for (claims) |a, i| {
        for (claims) |b, j| {
            if (i == j)
                continue;
            if (a.intersects(b))
                continue :outer;
        }

        return a;
    }

    return null;
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
