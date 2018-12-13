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

    const init = try readInitialState(allocator, &ps);
    defer allocator.free(init);
    _ = try scan(&ps, "\n", struct {});
    const notes = try readNotes(allocator, &ps);
    defer allocator.free(notes);

    const note_mask = compileNotes(notes);

    var arena_state = heap.ArenaAllocator.init(allocator);
    const arena = &arena_state.allocator;
    defer arena_state.deinit();

    // Sadly I had to look at reddit for this one. Did not think about the fact
    // that the input would stabilize (not all inputs do though
    // https://www.reddit.com/r/adventofcode/comments/a5eztl/comment/ebm4oec/)
    // This solution is a little messy. Ooh well.
    var sum_diff = std.ArrayList(isize).init(arena);
    var curr = init;
    var gen: usize = 0;
    var prev_sum: isize = sumState(init, 0);
    var sum = prev_sum;
    const repeating_diff = loop: while (gen < 50000000000) : (gen += 1) {
        curr = try simulate(arena, curr, note_mask);

        var off = @divExact(@intCast(isize, curr.len - init.len), 2) * 8;
        const curr_sum = sumState(curr, off);
        try sum_diff.append(curr_sum - prev_sum);
        prev_sum = curr_sum;

        // We just assume the sum has stabilize when the diff repeats 10 times
        const diffs = sum_diff.toSlice();
        const last = diffs[diffs.len - 1];
        sum += last;

        for (diffs) |_, i| {
            const index = diffs.len - (i + 1);
            if (diffs[index] != last)
                break;
            if (i == 10)
                break :loop last;
        }
    } else blk: {
        break :blk 0;
    };
    gen += 1;
    sum += @intCast(isize, 50000000000 - gen) * repeating_diff;

    try stdout.print("{}\n", sum);
}

fn readInitialState(allocator: *mem.Allocator, ps: var) ![]u8 {
    var state = std.ArrayList(u8).init(allocator);
    defer state.deinit();

    _ = try scan(ps, "initial state: ", struct {});

    var i: usize = 0;
    while (true) : (i += 1) {
        if (state.len <= (i / 8))
            try state.append(0);

        const curr = &state.toSlice()[i / 8];

        const c = try ps.stream.readByte();
        switch (c) {
            '#' => curr.* |= u8(1) << @intCast(u3, 8 - ((i % 8) + 1)),
            '.' => {},
            '\n' => return state.toOwnedSlice(),
            else => return error.InvalidInput,
        }
    }
}

fn readNotes(allocator: *mem.Allocator, ps: var) ![]Note {
    var notes = std.ArrayList(Note).init(allocator);
    defer notes.deinit();

    while (readNote(ps)) |note| {
        try notes.append(note);
        _ = try scan(ps, "\n", struct {});
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return notes.toOwnedSlice();
}

fn readNote(ps: var) !Note {
    var mask: u8 = 0;
    while (true) switch (try ps.stream.readByte()) {
        '#' => {
            mask <<= 1;
            mask |= 1;
        },
        '.' => mask <<= 1,
        ' ' => break,
        else => return error.InvalidInput,
    };
    _ = try scan(ps, "=> ", struct {});

    return Note{
        .mask = mask,
        .result = switch (try ps.stream.readByte()) {
            '#' => true,
            '.' => false,
            else => return error.InvalidInput,
        },
    };
}

fn simulate(allocator: *mem.Allocator, state: []const u8, note_mask: u32) ![]u8 {
    const res = try allocator.alloc(u8, state.len + 2);
    mem.set(u8, res, 0);

    for (res) |*b, i| {
        const left = if (i < 2) u8(0) else state[i - 2];
        const center = if (i < 1 or state.len <= i - 1) u8(0) else state[i - 1];
        const right = if (state.len <= i) u8(0) else state[i];
        const com: u16 = (u16(left) & 0b11) << 10 | u16(center) << 2 | ((u16(right) >> 6) & 0b11);

        comptime var j: usize = 0;
        inline while (j < @sizeOf(u8) * 8) : (j += 1) {
            const mask = (com >> @intCast(u5, j)) & u32(0b11111);
            b.* |= u8(@boolToInt(note_mask & (u32(1) << @intCast(u5, mask)) != 0)) << @intCast(u3, j);
        }
    }

    return res;
}

fn sumState(state: []const u8, off: isize) isize {
    var sum: isize = 0;
    for (state) |c, i| {
        var j: usize = 0;
        const s = @sizeOf(u8) * 8;
        while (j < s) : (j += 1) {
            const is_set = (c & (u8(1) << @intCast(u3, s - (j + 1)))) != 0;
            if (is_set) {
                sum += @intCast(isize, i * s + j) - off;
            }
        }
    }

    return sum;
}

fn compileNotes(notes: []const Note) u32 {
    var res: u32 = 0;
    for (notes) |n|
        res |= u32(@boolToInt(n.result)) << @intCast(u5, n.mask);

    return res;
}

fn sumF(comptime T: type, buf: []const T) isize {
    var res: isize = 0;
    for (buf) |item|
        res += item;

    return res;
}

const Note = struct {
    mask: u8,
    result: bool,
};
