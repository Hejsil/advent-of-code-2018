const fun = @import("fun");
const std = @import("std");

const io = std.io;
const os = std.os;

const scan = fun.scan.scan;

pub fn main() !void {
    const stdin = &(try io.getStdIn()).inStream().stream;
    const stdout = &(try io.getStdOut()).outStream().stream;
    var ps = io.PeekStream(1, os.File.InStream.Error).init(stdin);

    try stdout.print("{}\n", try sumLines(&ps));
}

fn sumLines(ps: var) !i64 {
    var sum: i64 = 0;
    while (scan(undefined, ps, "{}\n", struct {
        i: i64,
    })) |line| {
        sum += line.i;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return sum;
}
