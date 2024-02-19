const std = @import("std");
const stdin = std.io.getStdIn.reader();
const stdout = std.io.getStdOut().writer();
const assert = std.debug.assert;

test "example" {
    const StringReader = struct {
        const Self = @This();
        string: []const u8,
        index: u64 = 0,
        fn readByte(self: *Self) !u8 {
            if (self.index == std.math.maxInt(u64)) {
                return error.IndexTooLarge;
            }
            if (self.index == self.string.len) {
                return error.EndOfStream;
            }
            defer self.index += 1;
            return self.string[self.index];
        }
    };
    var reader = StringReader{
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
    var line = std.ArrayList(u8).init(std.testing.allocator);
    defer line.deinit();

    var number_str = std.ArrayList(u8).init(std.testing.allocator);
    defer number_str.deinit();

    var solver = Solver{
        .line = &line,
        .current_number_str = &number_str,
    };
    try solver.solve(&reader);
    assert(solver.total_sum == 4361);
}

const Token = enum {
    StartOfFile,
    Number,
    Symbol,
    Break,
};

const Solver = struct {
    const Self = @This();
    total_sum: u64 = 0,

    line: *std.ArrayList(u8),
    current_number_str: *std.ArrayList(u8),
    current_index: u64 = 0,
    current_token: Token = Token.StartOfFile,
    current_number: u64 = 0,
    current_number_start_idx: ?u64 = null,
    current_symbol_start_idx: ?u64 = null,

    pub fn handleByte(self: *Self, byte: u8) !void {
        defer self.current_index += 1;

        std.log.warn("INFO: line = \"{s}\"", .{self.line.items});
        std.log.info("INFO: {d} '{c}'", .{ byte, byte });

        switch (byte) {
            '\n' => try self.handleEndOfLine(),
            '0'...'9' => try self.handleNumber(byte),
            '.' => try self.handleDot(byte),
            else => try self.handleSymbol(byte),
        }
    }
    pub fn handleSymbol(self: *Self, byte: u8) !void {
        self.current_symbol_start_idx = self.current_index;
        self.current_token = Token.Symbol;

        try self.line.append(byte);
        self.current_number_str.clearRetainingCapacity();
    }
    pub fn handleNumber(self: *Self, byte: u8) !void {
        // building a number, there might be more digits later
        self.current_token = Token.Number;

        try self.current_number_str.append(byte);
        try self.line.append(byte);
    }
    pub fn handleDot(self: *Self, byte: u8) !void {
        self.current_token = Token.Break;

        self.current_number_str.clearRetainingCapacity();
        try self.line.append(byte);
    }
    pub fn handleEndOfLine(self: *Self) !void {
        self.current_token = Token.Break;

        self.current_number_str.clearRetainingCapacity();
        self.line.clearRetainingCapacity(); // TODO: do not clear
    }
    pub fn solve(self: *Self, reader: anytype) !void {
        while (true) {
            const byte = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    try self.handleEndOfLine();
                    break;
                },
                else => {
                    try stdout.print("Got error: {?}\n", .{err});

                    // std.log.err("Error while reading: {?}", err);
                    // The above std.log.err line fails to compile with the following error:
                    //     zig test ./day3/main.zig
                    //     /home/linuxbrew/.linuxbrew/Cellar/zig/0.11.0/lib/zig/std/fmt.zig:87:9: error: expected tuple or struct argument, found @typeInfo(@typeInfo(@TypeOf(main.test.example.StringReader.readByte)).Fn.return_type.?).ErrorUnion.error_set
                    //             @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
                    //             ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    //     make: *** [Makefile:2: run-day3] Error 1
                    //
                    //     [Process exited 2]
                    // However, stdout.print works fine.
                    return err;
                },
            };
            try self.handleByte(byte);
        }
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

    // Alternative approach (keep one single line in memoery, simple):
    // Read line[n] one byte at a time
    // Read line[n+1] one byte at a time and match each symbole or number with number or symboles in line[n] and update the same array after match is done, might have to do some acrobatics to make sure we don't overwrite a symbole or number too early. I can switch to one of the simpler approaches depending on how it unfolds.
    // repeat
    const solver = Solver{};
    try solver.solve(stdin);
}
