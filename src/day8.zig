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

    const tree = try readTree(allocator, &ps);
    defer tree.destroy();

    try stdout.print("{}\n", metadataSum(tree));
    try stdout.print("{}\n", treeValue(tree));
}

fn readTree(allocator: *mem.Allocator, ps: var) !*Tree {
    const tree = try Tree.create(allocator);
    errdefer tree.destroy();

    tree.root = try readNode(&tree.arena.allocator, ps);
    return tree;
}

fn readNode(allocator: *mem.Allocator, ps: var) anyerror!Node {
    const header = try scan(ps, "{} {} ", struct {
        nodes: u8,
        meta: u8,
    });

    var nodes = std.ArrayList(Node).init(allocator);
    defer nodes.deinit();

    var i: usize = 0;
    while (i < header.nodes) : (i += 1)
        try nodes.append(try readNode(allocator, ps));

    var metadata = std.ArrayList(u8).init(allocator);
    defer metadata.deinit();

    i = 0;
    while (i < header.meta) : (i += 1) {
        const res = try scan(ps, "{}", struct {
            meta: u8,
        });
        _ = try ps.stream.readByte();

        try metadata.append(res.meta);
    }

    return Node{
        .children = nodes.toOwnedSlice(),
        .metadata = metadata.toOwnedSlice(),
    };
}

const Tree = struct {
    root: Node,
    arena: heap.ArenaAllocator,

    fn create(allocator: *mem.Allocator) !*Tree {
        const tree = try allocator.create(Tree);
        tree.* = Tree{
            .root = Node{
                .children = ([*]Node)(undefined)[0..0],
                .metadata = ([*]u8)(undefined)[0..0],
            },
            .arena = undefined,
        };

        tree.arena = heap.ArenaAllocator.init(allocator);
        return tree;
    }

    fn destroy(tree: *Tree) void {
        const allocator = tree.arena.child_allocator;
        tree.arena.deinit();
        tree.* = undefined;
        allocator.destroy(tree);
    }
};

const Node = struct {
    children: []Node,
    metadata: []u8,
};

fn metadataSum(tree: *const Tree) usize {
    const Helper = struct {
        fn sum(node: Node) usize {
            var res: usize = 0;
            for (node.children) |child|
                res += sum(child);
            for (node.metadata) |data|
                res += data;

            return res;
        }
    };

    return Helper.sum(tree.root);
}

fn treeValue(tree: *const Tree) usize {
    const Helper = struct {
        fn nodeValue(node: Node) usize {
            var res: usize = 0;
            if (node.children.len == 0) {
                for (node.metadata) |data|
                    res += data;

                return res;
            }

            for (node.metadata) |data| {
                if (data == 0)
                    continue;
                if (node.children.len < data)
                    continue;

                res += nodeValue(node.children[data - 1]);
            }

            return res;
        }
    };

    return Helper.nodeValue(tree.root);
}
