const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

fn NewRunner(comptime T: anytype) type {
    return struct {
        const Self = @This();
        reader: T,
        fn run(self: *Self) !void {
            const b = try self.reader.readByte();
            try stdout.print("Hello '{c}'\n", .{b});
        }
    };
}

const Runner = struct {
    const Self = @This();
    fn run(_: Self, reader: anytype) !void {
        const b = try reader.readByte();
        try stdout.print("Hello '{c}'\n", .{b});
    }
};

const ConstReader = struct {
    fn readByte(_: ConstReader) !u8 {
        return 's';
    }
};

pub fn main() !void {
    var s1 = NewRunner(@TypeOf(stdin)){ .reader = stdin };
    try s1.run();

    const s2 = Runner{};
    try s2.run(stdin);

    const s3 = Runner{};
    try s3.run(ConstReader{});
}
