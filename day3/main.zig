const std = @import("std");
const assert = std.debug.assert;

test "example" {
    const StringReader = struct {
        const Self = @This();
        string: []const u8,
        fn readByte(_: Self) !void {}
    };
    _ = StringReader{
        .string =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
        ,
    };
    assert(1 == 1);
}

const Solver = struct {
    pub fn solve(_: *Solver, _: anytype) void {
        //
    }
};

pub fn main() void {
    // TODO:

    // First line (i==0):
    //   lineA = lines[0]
    //   Check all symbols on lineA and match with numbers on lineA
    // Take 2 lines at a time
    //   lineA = lines[i]
    //   lineB = lines[i+1]
    //   Check all symbols on lineA and match with numbers on lineB
    //   Check all symbols on lineB and match with numbers on lineA and lineB

    // Alternative approach:
    // Take 2 lines at a time
    //   lineA = lines[i]
    //   lineB = lines[i+1]
    //   Check all symbols (or numbers) on lineA and match with numbers (or symbols) on lineA
    //   Check all symbols on lineA and match with numbers on lineB
    //   Check all numbers on lineA and match with numbers on lineB

    // Alternative approach (one extra line in memory, but simpler):
    // Take 3 lines at a time
    //   lineA = lines[i]
    //   lineB = lines[i+1]
    //   lineC = lines[i+2]
    //   Check all symbols on lineB and match with numbers on lineA and lineC
}