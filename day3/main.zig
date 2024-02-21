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

        pub fn handleSymbol(self: *Line, current_index: u64) !void {
            self.symbol_index = current_index;
        }
        fn handleEndOfLine(self: *Line, current_index: u64) !void {
            try self.handleBreak(current_index);
        }
        fn handleBreak(self: *Line, current_index: u64) !void {
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

        var saw_break_top = false;
        var saw_break_bot = false;
        switch (top_byte) {
            '0'...'9' => {
                try self.top_line.handleNumber(top_byte, self.current_index);
            },
            '.', 'N' => {
                try self.top_line.handleBreak(self.current_index);
                saw_break_top = true;
            },
            '\n' => {
                try self.handleEndOfLine();
                saw_break_top = true;
            },
            else => {
                try self.top_line.handleBreak(self.current_index);
                try self.top_line.handleSymbol(self.current_index);

                saw_break_top = true;
            },
        }
        switch (bot_byte) {
            '0'...'9' => {
                try self.bot_line.handleNumber(bot_byte, self.current_index);
            },
            '.', 'N' => {
                try self.bot_line.handleBreak(self.current_index);
                saw_break_bot = true;
            },
            '\n' => {
                try self.handleEndOfLine();
                saw_break_bot = true;
            },
            else => {
                try self.bot_line.handleBreak(self.current_index);
                try self.bot_line.handleSymbol(self.current_index);
                saw_break_bot = true;
            },
        }

        const combinations = [_]struct { *Line, *Line }{
            .{ &self.top_line, &self.bot_line },
            .{ &self.bot_line, &self.top_line },
            .{ &self.bot_line, &self.bot_line },
            .{ &self.top_line, &self.top_line },
        };
        for (combinations, 0..) |comb, ii| {
            if (comb[0].symbol_index != null and comb[1].number_end_index != null and comb[1].number_start_index != null) {
                if (
                // saw a symbol
                comb[0].symbol_index.? == self.current_index
                // this symbol is after this number's end
                and comb[1].number_end_index.? + 1 == self.current_index) {
                    try stdout.print("YES1 {d} (combination[{d}])\n", .{ comb[1].current_number, ii });
                    self.total_sum += comb[1].current_number;
                    comb[1].current_number = 0;

                    try stdout.print("INDEX START {d}\n", .{comb[1].number_start_index.?});
                    try stdout.print("INDEX END   {d}\n", .{comb[1].number_end_index.?});
                    // TODO: we don't need to clear the top_line, because we already
                    // overwrite it with the bot_line
                    if (std.mem.eql(u8, comb[1].name, "bot")) {
                        for (comb[1].number_start_index.?..comb[1].number_end_index.?) |i| {
                            self.line.items[i] = 'N';
                        }
                    }
                }
            }
            if (comb[1].symbol_index != null and comb[0].number_end_index != null and comb[0].number_start_index != null) {
                if (
                // saw an end of a number
                comb[0].number_end_index.? == self.current_index
                // this number starts before this symbol
                and comb[1].symbol_index.? + 1 >= comb[0].number_start_index.?
                // this number ends after this symbol
                and comb[1].symbol_index.? <= comb[0].number_end_index.? + 1) {
                    try stdout.print("YES2 {d} (combination[{d}])\n", .{ comb[0].current_number, ii });
                    self.total_sum += comb[0].current_number;
                    comb[0].current_number = 0;

                    try stdout.print("INDEX START {d}\n", .{comb[0].number_start_index.?});
                    try stdout.print("INDEX END   {d}\n", .{comb[0].number_end_index.?});
                    if (std.mem.eql(u8, comb[0].name, "bot")) {
                        for (comb[0].number_start_index.?..comb[0].number_end_index.?) |i| {
                            self.line.items[i] = 'N';
                        }
                    }
                }
            }
        }
        if (saw_break_top) {
            self.top_line.number_start_index = null;
        }
        if (saw_break_bot) {
            self.bot_line.number_start_index = null;
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
