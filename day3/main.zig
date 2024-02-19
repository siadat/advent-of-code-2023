const std = @import("std");
const stdin = std.io.getStdIn().reader();
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

    const allocator = std.testing.allocator;

    var solver = try NewSolver(allocator);
    solver.init();
    defer allocator.destroy(solver);
    defer solver.deinit();

    try solver.solve(&reader);
    // assert(solver.total_sum == 4361);
}

fn NewSolver(allocator: std.mem.Allocator) !*Solver {
    // NOTE create on the heap, but the caller is responsible for freeing it, which is not nice at all.
    const solver = try allocator.create(Solver);
    solver.* = Solver{
        .allocator = allocator,
    };
    return solver;
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

    allocator: std.mem.Allocator,
    line: std.ArrayList(u8) = undefined,
    current_number_str: std.ArrayList(u8) = undefined,

    current_index: u64 = 0,
    current_token: Token = Token.StartOfFile,
    current_number_start_idx: ?u64 = null,
    current_symbol_start_idx: ?u64 = null,

    fn init(self: *Self) void {
        self.line = std.ArrayList(u8).init(self.allocator);
        self.current_number_str = std.ArrayList(u8).init(self.allocator);
    }
    fn deinit(self: *Self) void {
        self.line.deinit();
        self.current_number_str.deinit();
    }
    pub fn handleByte(self: *Self, byte: u8) !void {
        std.log.warn("INFO: line = \"{s}\"", .{self.line.items});
        std.log.warn("INFO: c = {d} '{c}'", .{ byte, byte });

        switch (byte) {
            '\n' => try self.handleEndOfLine(),
            '0'...'9' => try self.handleNumber(byte),
            '.' => try self.handleDot(byte),
            else => try self.handleSymbol(byte),
        }
    }
    fn getCurrentNumberIfAny(self: *Self) !?u64 {
        if (self.current_number_str.items.len == 0) {
            return null;
        }
        defer self.current_number_str.clearRetainingCapacity();
        defer self.current_number_start_idx = self.current_index;

        const number = try std.fmt.parseInt(u64, self.current_number_str.items, 10);
        std.log.warn("INFO: number = {d}", .{number});
        return number;
    }
    fn setLineByte(self: *Self, byte: u8) !void {
        if (self.current_index < self.line.items.len) {
            self.line.items[self.current_index] = byte;
        } else {
            try self.line.append(byte);
        }
    }
    pub fn handleSymbol(self: *Self, byte: u8) !void {
        defer self.current_index += 1;
        _ = try self.getCurrentNumberIfAny();

        self.current_symbol_start_idx = self.current_index;
        self.current_token = Token.Symbol;

        try self.setLineByte(byte);
    }
    pub fn handleNumber(self: *Self, byte: u8) !void {
        defer self.current_index += 1;

        // building a number, there might be more digits later
        self.current_token = Token.Number;

        try self.current_number_str.append(byte);
        try self.setLineByte(byte);
    }
    pub fn handleDot(self: *Self, byte: u8) !void {
        defer self.current_index += 1;
        _ = try self.getCurrentNumberIfAny();

        self.current_token = Token.Break;

        try self.setLineByte(byte);
    }
    pub fn handleEndOfLine(self: *Self) !void {
        _ = try self.getCurrentNumberIfAny();

        self.current_index = 0;
        self.current_token = Token.Break;
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
    var solver = try NewSolver(allocator);
    solver.init();
    defer allocator.destroy(solver);
    defer solver.deinit();

    try solver.solve(stdin);
}
