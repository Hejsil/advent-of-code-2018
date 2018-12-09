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

    const input = try scan(&ps, "{} players; last marble is worth {} points", struct {
        players: usize,
        last_marble: usize,
    });

    try stdout.print("{}\n", try simulateElfGame(allocator, input.players, input.last_marble));
}

fn simulateElfGame(allocator: *mem.Allocator, players: usize, last_marble: usize) !usize {
    const scores = try allocator.alloc(usize, players);
    defer allocator.free(scores);
    mem.set(usize, scores, 0);

    var circle = std.ArrayList(usize).init(allocator);
    defer circle.deinit();

    try circle.append(0);

    var curr: usize = 0;
    var marble: usize = 1;
    var player: usize = 0;
    while (true) : ({
        player = (player + 1) % players;
        marble += 1;
    }) {
        if (last_marble == marble)
            return max(usize, scores, lessThan).?;

        if (marble % 23 == 0) {
            curr = ((circle.len + curr) - 7) % circle.len;

            const circle_slice = circle.toSlice();
            const points = marble + circle_slice[curr];
            scores[player] += points;

            mem.copy(usize, circle_slice[curr..], circle_slice[curr + 1 ..]);
            _ = circle.pop();
            continue;
        }

        curr = (curr + 2) % circle.len;
        try circle.insert(curr, marble);
    }
}

fn max(comptime T: type, slice: []const T, lt: fn (T, T) bool) ?T {
    if (slice.len == 0)
        return null;

    var res = slice[0];
    for (slice[0..]) |item| {
        if (lt(res, item))
            res = item;
    }

    return res;
}

fn lessThan(a: usize, b: usize) bool {
    return a < b;
}
