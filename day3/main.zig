const std = @import("std");
const assert = std.debug.assert;

test "example" {
    const StringReader = struct {
        const Self = @This();
        string: []const u8,
        fn readByte(_: Self) !void {}
    };
    const reader = StringReader{
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
    var solver = Solver{};
    solver.solve(reader);
    assert(solver.total_sum == 4361);
}

const Solver = struct {
    total_sum: u64 = 0,
    symbol_line_idx: u64 = 0,

    line_prev: []const u8 = "",
    line_curr: []const u8 = "",
    line_next: []const u8 = "",

    pub fn solve(_: *Solver, _: anytype) void {}
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

    // Alternative approach (keep one single line in memoery, simple):
    // Read line[n] one byte at a time
    // Read line[n+1] one byte at a time and match each symbole or number with number or symboles in line[n] and update the same array after match is done
    // repeat
}
