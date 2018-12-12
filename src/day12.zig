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

    var arena_state = heap.ArenaAllocator.init(allocator);
    const arena = &arena_state.allocator;
    defer arena_state.deinit();

    //for (notes) |n| {
    //    dumpMask(n.mask);
    //}

    var curr = init;
    var gen: usize = 0;
    while (gen < 50000000000) : (gen += 1) {
        //dumpState(curr);
        if (gen % 1000 == 0) debug.warn("{}\n", gen);
        curr = try simulate(arena, curr, notes);
    }
    //dumpState(curr);

    var off = @divExact(@intCast(isize, curr.len - init.len), 2);
    var sum: isize = 0;
    for (curr) |c, i|
        sum += if (c) @intCast(isize, i) - off else 0;

    try stdout.print("{}\n", sum);
}

fn readInitialState(allocator: *mem.Allocator, ps: var) ![]bool {
    var state = std.ArrayList(bool).init(allocator);
    defer state.deinit();

    _ = try scan(ps, "initial state: ", struct {});

    while (true) switch (try ps.stream.readByte()) {
        '#' => try state.append(true),
        '.' => try state.append(false),
        '\n' => return state.toOwnedSlice(),
        else => return error.InvalidInput,
    };
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

fn simulate(allocator: *mem.Allocator, state: []const bool, notes: []const Note) ![]bool {
    const size = blk: {
        var size: usize = state.len;
        for (state) |c, i| {
            if (c or state[state.len - (i + 1)])
                break;
            size -= 1;
        }

        break :blk size;
    };
    const res = try allocator.alloc(bool, state.len + 4 * 2);
    mem.set(bool, res, false);

    var mask: usize = 0;
    for (res[2 .. res.len - 2]) |*c, i| {
        mask <<= 1;
        mask |= if (state.len <= i) u8(0) else @boolToInt(state[i]);
        mask &= 0b11111;

        for (notes) |n| {
            if (mask == n.mask) {
                c.* = n.result;
                break;
            }
        }
    }

    return res;
}

fn dumpMask(mask: usize) void {
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        debug.warn("{c}", if (mask & (u8(1) << @intCast(u3, 5 - (i + 1))) != 0) u8('#') else u8('.'));
    }
    debug.warn("\n");
}

fn dumpState(state: []const bool) void {
    for (state) |s|
        debug.warn("{c}", if (s) u8('#') else u8('.'));
    debug.warn("\n");
}

const Note = struct {
    mask: u8,
    result: bool,
};
