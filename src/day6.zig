const std = @import("std");
const fun = @import("fun");

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

    const points = try readPoints(allocator, &ps);

    try stdout.print("{}\n", try findBiggestFiniteArea(allocator, points));
    try stdout.print("{}\n", try findRegionAreaFromDistanceToPoints(10000, points));
}

fn readPoints(allocator: *mem.Allocator, ps: var) ![]Point {
    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();

    while (scan(ps, "{}, {}\n", Point)) |point| {
        try points.append(point);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return points.toOwnedSlice();
}

fn findBiggestFiniteArea(allocator: *mem.Allocator, points: []const Point) !isize {
    if (points.len == 0)
        return error.NoInput;

    const infinit: isize = math.minInt(isize);
    const size = max(Point, points, Point.lessThan) orelse return error.NoInput;

    const areas = try allocator.alloc(isize, points.len);
    defer allocator.free(areas);

    mem.set(isize, areas, 0);

    var x: usize = 0;
    while (x < size.x) : (x += 1) {
        var y: usize = 0;
        while (y < size.y) : (y += 1) {
            const p = Point{ .x = x, .y = y };
            const i = closestPoint(p, points) orelse continue;
            if (x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1) {
                areas[i] = infinit;
            } else {
                areas[i] += 1;
            }
        }
    }

    return max(isize, areas, struct {
        fn lessThan(a: isize, b: isize) bool {
            return a < b;
        }
    }.lessThan).?;
}

fn findRegionAreaFromDistanceToPoints(max_dist: usize, points: []const Point) !usize {
    var area: usize = 0;
    const size = max(Point, points, Point.lessThan) orelse return error.NoInput;

    var x: usize = 0;
    while (x < size.x) : (x += 1) {
        var y: usize = 0;
        while (y < size.y) : (y += 1) {
            const p1 = Point{ .x = x, .y = y };
            var dist: usize = 0;
            for (points) |p2| {
                dist += p1.distance(p2);
            }
            if (dist < max_dist)
                area += 1;
        }
    }

    return area;
}

fn maxIndex(comptime T: type, slice: []const T, comptime lessThan: fn (T, T) bool) ?usize {
    if (slice.len == 0)
        return null;

    var res: usize = 0;
    for (slice[0..]) |_, i| {
        if (lessThan(slice[res], slice[i]))
            res = i;
    }

    return res;
}

fn max(comptime T: type, slice: []const T, comptime lessThan: fn (T, T) bool) ?T {
    const i = maxIndex(T, slice, lessThan) orelse return null;
    return slice[i];
}

fn closestPoint(point: Point, points: []const Point) ?usize {
    if (points.len == 0)
        return null;

    var min_i: ?usize = null;
    var min_dist: usize = math.maxInt(usize);
    for (points[0..]) |item, i| {
        const item_dist = item.distance(point);
        if (item_dist == min_dist) {
            min_i = null;
        } else if (item_dist < min_dist) {
            min_dist = item_dist;
            min_i = i;
        }
    }

    return min_i;
}

const Point = struct {
    x: usize,
    y: usize,

    const zero = Point{ .x = 0, .y = 0 };

    fn lessThan(a: Point, b: Point) bool {
        return a.distance(zero) < b.distance(zero);
    }

    fn equal(a: Point, b: Point) bool {
        return a.x == b.x and a.y == b.y;
    }

    fn distance(a: Point, b: Point) u64 {
        return (math.sub(u64, a.x, b.x) catch b.x - a.x) +
            (math.sub(u64, a.y, b.y) catch b.y - a.y);
    }
};
