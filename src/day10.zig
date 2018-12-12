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
    defer allocator.free(points);

    var seconds: usize = 0;
    while (pointsWithNeighbor(points) < points.len) : (seconds += 1) {
        for (points) |*p|
            p.update();
    }
    try printPoints(points, stdout);
    try stdout.print("{}\n", seconds);
}

fn readPoints(allocator: *mem.Allocator, ps: var) ![]Point {
    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();

    while (readPoint(ps)) |point| {
        try points.append(point);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return points.toOwnedSlice();
}

fn readPoint(ps: var) !Point {
    _ = try scan(ps, "position=<", struct {});
    try skipSpaces(ps);
    const pos1 = try scan(ps, "{},", struct {
        x: isize,
    });
    try skipSpaces(ps);
    const pos2 = try scan(ps, "{}> velocity=<", struct {
        y: isize,
    });
    try skipSpaces(ps);
    const vel1 = try scan(ps, "{},", struct {
        x: isize,
    });
    try skipSpaces(ps);
    const vel2 = try scan(ps, "{}>\n", struct {
        y: isize,
    });

    return Point{
        .pos_x = pos1.x,
        .pos_y = pos2.y,
        .vel_x = vel1.x,
        .vel_y = vel2.y,
    };
}

fn skipSpaces(ps: var) !void {
    while (ps.stream.readByte()) |c| switch (c) {
        ' ' => {},
        else => {
            ps.putBackByte(c);
            return;
        },
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
}

fn pointsWithNeighbor(points: []const Point) usize {
    var res: usize = 0;
    outer: for (points) |p1| {
        for (points) |p2| {
            const dist = p1.distance(p2);
            if (dist == 1 or dist == 2) {
                res += 1;
                continue :outer;
            }
        }
    }

    return res;
}

fn printPoints(points: []const Point, stream: var) !void {
    var min_x: isize = math.maxInt(isize);
    var min_y: isize = math.maxInt(isize);
    var max_x: isize = math.minInt(isize);
    var max_y: isize = math.minInt(isize);
    for (points) |p| {
        if (p.pos_x < min_x)
            min_x = p.pos_x;
        if (p.pos_y < min_y)
            min_y = p.pos_y;
        if (p.pos_x > max_x)
            max_x = p.pos_x;
        if (p.pos_y > max_y)
            max_y = p.pos_y;
    }

    var y = min_y;
    while (y <= max_y) : (y += 1) {
        var x = min_x;
        while (x <= max_x) : (x += 1) {
            const p = Point{ .pos_x = x, .pos_y = y, .vel_x = 0, .vel_y = 0 };
            if (find(Point, points, p, Point.equal)) |p2| {
                try stream.print("#");
            } else {
                try stream.print(".");
            }
        }

        try stream.print("\n");
    }
}

pub const Point = struct {
    pos_x: isize,
    pos_y: isize,
    vel_x: isize,
    vel_y: isize,

    fn update(p: *Point) void {
        p.pos_x += p.vel_x;
        p.pos_y += p.vel_y;
    }

    fn equal(a: Point, b: Point) bool {
        return a.distance(b) == 0;
    }

    fn distance(a: Point, b: Point) usize {
        return math.absCast(a.pos_x - b.pos_x) + math.absCast(a.pos_y - b.pos_y);
    }
};

fn find(comptime T: type, slice: []const T, item: T, comptime eql: fn (T, T) bool) ?*const T {
    for (slice) |*i| {
        if (eql(i.*, item))
            return i;
    }

    return null;
}
