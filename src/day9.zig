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
    try stdout.print("{}\n", try simulateElfGame(allocator, input.players, input.last_marble * 100));
}

fn simulateElfGame(child_allocator: *mem.Allocator, players: usize, last_marble: usize) !usize {
    const scores = try child_allocator.alloc(usize, players);
    defer child_allocator.free(scores);
    mem.set(usize, scores, 0);

    const Circle = std.LinkedList(usize);
    const marbles_allocated = (last_marble - (last_marble / 23)) + 1;
    const buf = try child_allocator.alloc(u8, marbles_allocated * @sizeOf(Circle));
    defer child_allocator.free(buf);

    var fba = heap.FixedBufferAllocator.init(buf[0..]);
    const allocator = &fba.allocator;

    var player: usize = 0;
    var marble: usize = 1;
    var circle = std.LinkedList(usize).init();
    var curr = try circle.createNode(0, allocator);
    curr.prev = curr;
    curr.next = curr;
    circle.first = curr;
    circle.last = curr;
    circle.len = 1;

    while (marble <= last_marble) : ({
        player = (player + 1) % players;
        marble += 1;
    }) {
        if (marble % 23 == 0) {
            var i: usize = 0;
            while (i < 7) : (i+= 1)
                curr = curr.prev.?;


            scores[player] += curr.data + marble;
            circle.remove(curr);
            curr = curr.next.?;
        } else {
            const next = try circle.createNode(marble, allocator);
            curr = curr.next.?;
            circle.insertAfter(curr, next);
            curr = next;
        }

    }

    return mem.max(usize, scores);
}
