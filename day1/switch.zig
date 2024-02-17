const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Tuple = struct {
    char1: u8,
    char2: u8,
};

fn hash(tuple: Tuple) u64 {
    return (@as(u64, tuple.char1)) << 8 | (@as(u64, tuple.char2));
}

pub fn main() !void {
    const char1: u8 = 'A';
    const char2: u8 = 'B';
    const val = hash(Tuple{ .char1 = char1, .char2 = char2 });
    const x = hash(Tuple{ .char1 = 'D', .char2 = 'E' });
    switch (val) {
        // hash(Tuple{ .char1 = 'A', .char2 = 'B' }) => 'Y',
        x => 'Y',
        else => 'N',
    }
    try stdout.print("char1={c} char2={c} char3={c}\n", .{ char1, char2, -1 });
}
