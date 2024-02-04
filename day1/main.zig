const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const assert = std.debug.assert;

const Calculator = struct {
    total_sum: u64 = 0,
    line_first_num: u64 = 0,
    line_last_num: u64 = 0,

    pub fn handleByte(self: *Calculator, byte: u8) !void {
        if (byte == '\n') {
            try self.handleEndOfLine();
        } else if (byte >= '1' and byte <= '9') {
            self.handleNumberByte(byte);
        } else {
            // no op
        }
    }
    pub fn handleNumberByte(self: *Calculator, byte: u8) void {
        const value = byte - '1' + 1;
        if (self.line_first_num == 0) {
            self.line_first_num = value;
        }
        self.line_last_num = value;
    }
    pub fn handleEndOfLine(self: *Calculator) !void {
        try stdout.print("{}+{}\n\n", .{ self.line_first_num, self.line_last_num });
        self.total_sum += 10 * self.line_first_num + self.line_last_num;
        self.line_first_num = 0;
        self.line_last_num = 0;
    }
};

pub fn main() !void {
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    var calculator = Calculator{};

    while (true) {
        const byte = stdin.readByte() catch |err| switch (err) {
            error.EndOfStream => {
                try calculator.handleEndOfLine();
                break;
            },
            else => {
                try stdout.print("Ooops", .{});
                return err;
            },
        };
        try stdout.print("{c}", .{byte});
        try calculator.handleByte(byte);
    }
    try stdout.print("total_sum: {}\n", .{calculator.total_sum});
    assert(54940 == calculator.total_sum);
}
