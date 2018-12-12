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

    const input = try scan(&ps, "{}", struct {
        serial_number: usize,
    });
    const grid = makeGrid(input.serial_number);
    const p = findSquareWithLargestSum(grid, 3, 3).?;
    try stdout.print("{},{}\n", p.x, p.y);

    var max = findSquareWithLargestSum(grid, 1, 1).?;
    var size: usize = 1;
    var i: usize = 2;
    while (i <= grid.len) : (i += 1) {
        const sq = findSquareWithLargestSum(grid, i, i).?;
        if (max.sum < sq.sum) {
            size = i;
            max = sq;
        }
    }
    try stdout.print("{},{},{}\n", max.x, max.y, size);
}

fn findSquareWithLargestSum(grid: var, size_x: usize, size_y: usize) ?Point {
    var largest: ?Point = null;

    if (size_x == 0)
        return null;
    if (size_y == 0)
        return null;
    if (grid.len < size_y)
        return null;
    if (grid[0].len < size_x)
        return null;

    for (grid[0 .. grid.len - size_y]) |*_, y| {
        for (grid[0 .. grid.len - size_y]) |_, x| {
            var sum: isize = 0;
            for (grid[y .. size_y + y]) |*col| {
                for (col[x .. size_x + x]) |p| {
                    sum += p;
                }
            }

            if (largest) |*l| {
                if (l.sum < sum) {
                    l.* = Point{ .x = x, .y = y, .sum = sum };
                }
            } else {
                largest = Point{ .x = x, .y = y, .sum = sum };
            }
        }
    }

    return largest;
}

const Point = struct {
    x: usize,
    y: usize,
    sum: isize,
};

fn makeGrid(serial_number: usize) [300][300]isize {
    var res = [][300]isize{[]isize{0} ** 300} ** 300;
    for (res) |*row, y| {
        for (row) |*p, x|
            p.* = calcPower(x, y, serial_number);
    }

    return res;
}

fn calcPower(x: usize, y: usize, serial_number: usize) isize {
    const rack_id = x + 10;
    const power = rack_id * y + serial_number;
    const power2 = power * rack_id;
    const digit = (power2 / 100) % 10;
    return @intCast(isize, digit) - 5;
}

test "calcPower" {
    debug.assert(calcPower(3, 5, 8) == 4);
    debug.assert(calcPower(122, 79, 57) == -5);
    debug.assert(calcPower(217, 196, 39) == 0);
    debug.assert(calcPower(101, 153, 71) == 4);
}
