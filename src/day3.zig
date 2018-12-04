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

    const overlaps = try fabricOverlaps(allocator, claims);
    defer allocator.free(overlaps);

    try stdout.print("{}\n", count(usize, overlaps, above1));
    const claim = firstNoneIntersectingClaim(claims) orelse return error.NoPerfectClaim;
    try stdout.print("{}\n", claim.id);
}

fn readClaims(allocator: *mem.Allocator, ps: var) ![]Claim {
    var claims = std.ArrayList(Claim).init(allocator);
    defer claims.deinit();

    while (scan(undefined, ps, "#{} @ {},{}: {}x{}\n", Claim)) |claim| {
        try claims.append(claim);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return claims.toOwnedSlice();
}

fn fabricOverlaps(allocator: *mem.Allocator, claims: []const Claim) ![]usize {
    var fabric_width: usize = 0;
    var fabric_height: usize = 0;
    for (claims) |claim| {
        fabric_width = math.max(fabric_width, claim.width + claim.x);
        fabric_height = math.max(fabric_height, claim.height + claim.y);
    }

    const fabric = try allocator.alloc(usize, fabric_width * fabric_height);
    errdefer allocator.free(fabric);
    mem.set(usize, fabric, 0);

    for (claims) |claim| {
        var x: usize = claim.x;
        while (x < claim.width + claim.x) : (x += 1) {
            var y: usize = claim.y;
            while (y < claim.height + claim.y) : (y += 1) {
                fabric[x + (fabric_width * y)] += 1;
            }
        }
    }

    return fabric;
}

fn count(comptime T: type, slice: []const T, predicate: fn (T) bool) usize {
    var res: usize = 0;
    for (slice) |item|
        res += @boolToInt(predicate(item));

    return res;
}

fn above1(i: usize) bool {
    return i > 1;
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
        const Point = struct {
            x: usize,
            y: usize,
        };

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
