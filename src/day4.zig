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

    const records = try readRecords(allocator, &ps);
    defer allocator.free(records);

    std.sort.sort(Record, records, Record.lessThan);

    var schedule = try sleepSchedule(allocator, records);
    defer schedule.deinit();

    try stdout.print("{}\n", strategy1(schedule));
    try stdout.print("{}\n", strategy2(schedule));
}

fn readRecords(allocator: *mem.Allocator, ps: var) ![]Record {
    var records = std.ArrayList(Record).init(allocator);
    defer records.deinit();

    while (readRecord(ps)) |record| {
        try records.append(record);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return records.toOwnedSlice();
}

fn readRecord(ps: var) !Record {
    const time = try scan(undefined, ps, "[{}-{}-{} {}:{}] ", Time);
    const next = try ps.stream.readByte();
    const kind = switch (next) {
        'G' => blk: {
            const res = try scan(undefined, ps, "uard #{} begins shift\n", struct {
                id: u16,
            });
            break :blk Record.Kind{ .ShiftBegins = res.id };
        },
        'f' => blk: {
            _ = try scan(undefined, ps, "alls asleep\n", struct {});
            break :blk Record.Kind{ .FallsAsleep = {} };
        },
        'w' => blk: {
            _ = try scan(undefined, ps, "akes up\n", struct {});
            break :blk Record.Kind{ .WakesUp = {} };
        },
        else => return error.InvalidCharacter,
    };

    return Record{
        .time = time,
        .kind = kind,
    };
}

fn sleepSchedule(allocator: *mem.Allocator, records: []const Record) !SleepSchedule {
    const State = union(enum) {
        Begin,
        Awake: *SleepSchedule.KV,
        Sleeps: Sleeps,

        const Sleeps = struct {
            start: Time,
            guard: *SleepSchedule.KV,
        };
    };

    var state: State = State.Begin;
    var res = SleepSchedule.init(allocator);
    errdefer {
        var iter = res.iterator();
        while (iter.next()) |guard|
            guard.value.deinit();

        res.deinit();
    }

    for (records) |record|
        switch (state) {
        State.Begin => switch (record.kind) {
            Record.Kind.ShiftBegins => |guard_id| {
                const kv = try res.getOrPutValue(guard_id, std.ArrayList(Sleep).init(allocator));
                state = State{ .Awake = kv };
            },
            else => return error.InvalidInput,
        },
        State.Awake => |guard| switch (record.kind) {
            Record.Kind.ShiftBegins => |guard_id| {
                const kv = try res.getOrPutValue(guard_id, std.ArrayList(Sleep).init(allocator));
                state = State{ .Awake = kv };
            },
            Record.Kind.FallsAsleep => state = State{
                .Sleeps = State.Sleeps{
                    .start = record.time,
                    .guard = guard,
                },
            },
            else => return error.InvalidInput,
        },
        @TagType(State).Sleeps => |sleeps| switch (record.kind) {
            Record.Kind.WakesUp => {
                try sleeps.guard.value.append(Sleep{
                    .start = sleeps.start,
                    .end = record.time,
                });
                state = State{ .Awake = sleeps.guard };
            },
            else => return error.InvalidInput,
        },
    };

    switch (state) {
        State.Begin => {},
        State.Awake => {},
        @TagType(State).Sleeps => return error.InvalidInput,
    }

    return res;
}

fn strategy1(schedule: SleepSchedule) usize {
    const Best = struct {
        guard: u16,
        minutes: u64,
        minut_most_asleep: usize,
    };

    var best = Best{
        .guard = 0,
        .minutes = 0,
        .minut_most_asleep = 0,
    };
    var iter = schedule.iterator();
    while (iter.next()) |guard| {
        var minutes = []usize{0} ** 60;
        for (guard.value.toSlice()) |sleep| {
            var min = sleep.start.min;
            while (min < sleep.end.min) : (min += 1)
                minutes[min] += 1;
        }

        const asleep_for = sum(usize, minutes);
        if (best.minutes < asleep_for) {
            best = Best{
                .guard = guard.key,
                .minutes = asleep_for,
                .minut_most_asleep = maxIndex(usize, minutes).?,
            };
        }
    }

    return best.guard * best.minut_most_asleep;
}

fn strategy2(schedule: SleepSchedule) usize {
    const Best = struct {
        guard: u16,
        minutes: u64,
        minut_most_asleep: usize,
    };

    var best = Best{
        .guard = 0,
        .minutes = 0,
        .minut_most_asleep = 0,
    };
    var iter = schedule.iterator();
    while (iter.next()) |guard| {
        var minutes = []usize{0} ** 60;
        for (guard.value.toSlice()) |sleep| {
            var min = sleep.start.min;
            while (min < sleep.end.min) : (min += 1)
                minutes[min] += 1;
        }

        const minut_most_asleep = maxIndex(usize, minutes).?;
        if (best.minutes < minutes[minut_most_asleep]) {
            best = Best{
                .guard = guard.key,
                .minutes = minutes[minut_most_asleep],
                .minut_most_asleep = minut_most_asleep,
            };
        }
    }

    return best.guard * best.minut_most_asleep;
}

fn sum(comptime T: type, buf: []const T) u64 {
    var res: u64 = 0;
    for (buf) |item|
        res += item;

    return res;
}

fn maxIndex(comptime T: type, buf: []const T) ?usize {
    if (buf.len == 0)
        return null;

    var res: usize = 0;
    for (buf[1..]) |item, i| {
        if (buf[res] < item)
            res = i + 1;
    }

    return res;
}

const Record = struct {
    time: Time,
    kind: Kind,

    const Kind = union(enum) {
        ShiftBegins: u16,
        FallsAsleep,
        WakesUp,
    };

    fn lessThan(a: Record, b: Record) bool {
        return a.time.lessThan(b.time);
    }
};

const Time = struct {
    year: u16,
    month: u8,
    day: u8,
    hour: u8,
    min: u8,

    fn lessThan(a: Time, b: Time) bool {
        inline for (@typeInfo(Time).Struct.fields) |f| {
            if (@field(a, f.name) < @field(b, f.name))
                return true;
            if (@field(a, f.name) > @field(b, f.name))
                return false;
        }

        return false;
    }
};

const SleepSchedule = std.AutoHashMap(u16, std.ArrayList(Sleep));

const Sleep = struct {
    start: Time,
    end: Time,
};
