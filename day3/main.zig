const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const assert = std.debug.assert;

test "example_simple" {
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
    const test_cases = [_]struct { input: []const u8, want: u64 }{
        .{ .input = 
        \\**********
        \\**********
        \\****5*****
        \\**********
        \\**********
        , .want = 5 },

        .{ .input = 
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
        , .want = 4361 },

        .{ .input = 
        \\..555555..
        \\..55**55..
        \\..555555..
        , .want = 555555 + 555555 + 55 + 55 },

        .{ .input = 
        \\..5.......
        \\....*.*...
        \\..........
        , .want = 0 },

        .{ .input = 
        \\...5......
        \\....*..*..
        \\..........
        , .want = 5 },

        .{ .input = 
        \\..55......
        \\....*.....
        \\..........
        , .want = 55 },

        .{ .input = 
        \\......55..
        \\.....*....
        \\..........
        , .want = 55 },

        .{ .input = 
        \\..........
        \\.....*....
        \\......55..
        , .want = 55 },

        .{ .input = 
        \\..........
        \\....*.....
        \\..55......
        , .want = 55 },

        .{ .input = 
        \\..........
        \\....*.....
        \\....55....
        , .want = 55 },

        .{ .input = 
        \\..........
        \\.......*55
        \\..........
        , .want = 55 },

        .{ .input = 
        \\..........
        \\55*.......
        \\..........
        , .want = 55 },
    };

    for (test_cases) |tc| {
        var reader = StringReader{
            .string = tc.input,
        };
        const allocator = std.testing.allocator;
        var solver = Solver.init(allocator);
        defer solver.deinit();
        try solver.solve(&reader);
        std.log.warn("total_sum = {d}\n", .{solver.total_sum});
        assert(solver.total_sum == tc.want);
    }
}

const Token = enum {
    StartOfFile,
    Number,
    Symbol,
    Break,
};

const Solver = struct {
    const Self = @This();

    const Line = struct {
        name: []const u8,
        current_number: u64 = 0,
        current_number_str: std.ArrayList(u8) = undefined,
        current_number_matched: bool = false,

        symbol_index: ?u64 = null,
        number_start_index: ?u64 = null,
        number_end_index: ?u64 = null,
        break_seen: bool = false,

        fn matchWith(self: *Line, other: *Line, current_index: u64, line: std.ArrayList(u8)) !u64 {
            var sum: u64 = 0;
            if (
            //
            self.symbol_index != null
            //
            and other.number_end_index != null
            //
            and other.number_start_index != null) {
                if (
                // saw a symbol
                self.symbol_index.? == current_index
                // this symbol is after this number's end
                and other.number_end_index.? + 1 == current_index) {
                    sum += other.current_number;
                    other.current_number = 0;

                    // We don't need to clear the top_line, because we already
                    // overwrite it with the bot_line
                    if (std.mem.eql(u8, other.name, "bot")) {
                        for (other.number_start_index.?..other.number_end_index.?) |i| {
                            // clear number to avoid double counting
                            line.items[i] = 'N';
                        }
                    }
                }
            }
            if (
            //
            other.symbol_index != null
            //
            and self.number_end_index != null
            //
            and self.number_start_index != null) {
                if (
                // saw an end of a number
                self.number_end_index.? == current_index
                // this number starts before this symbol
                and other.symbol_index.? + 1 >= self.number_start_index.?
                // this number ends after this symbol
                and other.symbol_index.? <= self.number_end_index.? + 1) {
                    sum += self.current_number;
                    self.current_number = 0;

                    // We don't need to clear the top_line, because we already
                    // overwrite it with the bot_line
                    if (std.mem.eql(u8, self.name, "bot")) {
                        for (self.number_start_index.?..self.number_end_index.?) |i| {
                            // clear number to avoid double counting
                            line.items[i] = 'N';
                        }
                    }
                }
            }
            return sum;
        }
        pub fn handleSymbol(self: *Line, current_index: u64) !void {
            self.symbol_index = current_index;
        }
        fn handleEndOfLine(self: *Line, current_index: u64) !void {
            try self.handleBreak(current_index);
        }
        fn onByte(self: *Line, byte: u8, current_index: u64) !void {
            self.break_seen = false;
            switch (byte) {
                '0'...'9' => try self.handleNumber(byte, current_index),
                '.', 'N' => try self.handleBreak(current_index),
                '\n' => try self.handleEndOfLine(current_index),
                else => {
                    // symbole
                    try self.handleBreak(current_index);
                    try self.handleSymbol(current_index);
                },
            }
        }
        fn onAfterByte(self: *Line) void {
            if (self.break_seen) {
                self.number_start_index = null;
            }
        }
        fn handleBreak(self: *Line, current_index: u64) !void {
            self.break_seen = true;
            if (self.current_number_str.items.len == 0) {
                return;
            }
            self.number_end_index = current_index;
            self.current_number = try std.fmt.parseInt(u64, self.current_number_str.items, 10);
            self.current_number_str.clearRetainingCapacity();
        }
        fn handleNumber(self: *Line, byte: u8, current_index: u64) !void {
            self.current_number = 0;
            self.number_start_index = current_index -% self.current_number_str.items.len;
            self.number_end_index = null; // why is this needed?
            try self.current_number_str.append(byte);
        }
    };

    top_line: Line = undefined,
    bot_line: Line = undefined,

    total_sum: u64 = 0,

    allocator: std.mem.Allocator = undefined,
    line: std.ArrayList(u8) = undefined,
    current_index: u64 = 0,

    fn initLine(allocator: std.mem.Allocator, name: []const u8) Line {
        return Line{
            .name = name,
            .current_number_str = std.ArrayList(u8).init(allocator),
        };
    }

    fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .line = std.ArrayList(u8).init(allocator),
            .top_line = Solver.initLine(allocator, "top"),
            .bot_line = Solver.initLine(allocator, "bot"),
        };
    }

    fn deinit(self: *Self) void {
        self.line.deinit();
        self.top_line.current_number_str.deinit();
        self.bot_line.current_number_str.deinit();
    }

    pub fn handleByte(self: *Self, new_byte: u8) !void {
        if (new_byte == '\n') {
            try stdout.print("INFO: line = \"{s}\" got {c}", .{ self.line.items[0..self.current_index], new_byte });
        }
        //std.log.warn("INFO: c = {d} '{c}'", .{ new_byte, new_byte });

        const top_byte = blk: {
            if (self.line.items.len <= self.current_index) {
                // first line, no top byte
                break :blk '.';
            }
            break :blk self.line.items[self.current_index];
        };
        const bot_byte = new_byte;
        defer {
            if (new_byte == '\n') {
                self.current_index = 0;
            } else {
                self.setLineByte(bot_byte) catch |err| switch (err) {
                    else => std.log.warn("FAEILD TO SET LINE {any}\n", .{err}),
                };
                self.current_index += 1;
            }
        }

        try self.top_line.onByte(top_byte, self.current_index);
        try self.bot_line.onByte(bot_byte, self.current_index);
        defer self.top_line.onAfterByte();
        defer self.bot_line.onAfterByte();

        const combinations = [_]struct { *Line, *Line }{
            .{ &self.top_line, &self.bot_line },
            .{ &self.bot_line, &self.top_line },
            .{ &self.bot_line, &self.bot_line },
        };
        for (combinations) |comb| {
            self.total_sum += try comb[0].matchWith(
                comb[1],
                self.current_index,
                self.line,
            );
        }
    }

    fn setLineByte(self: *Self, byte: u8) !void {
        if (self.current_index < self.line.items.len) {
            self.line.items[self.current_index] = byte;
        } else {
            try self.line.append(byte);
        }
    }
    pub fn handleEndOfLine(self: *Self) !void {
        try self.top_line.handleEndOfLine(self.current_index);
        try self.bot_line.handleEndOfLine(self.current_index);
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.log.err("There is memory leak\n", .{});
        }
    }
    const allocator = gpa.allocator();
    var solver = Solver.init(allocator);
    defer solver.deinit();

    var reader = stdin;
    if (false) {
        // read from normal file
        const file = try std.fs.cwd().openFile("day3/input.txt", .{});
        reader = file.reader();
    }

    try solver.solve(reader);
    std.log.warn("total_sum = {d}\n", .{solver.total_sum});
    assert(solver.total_sum == 520019);
}
