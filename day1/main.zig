const std = @import("std");
const assert = std.debug.assert;
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

// The goal of this implementation was to:
// 1. Learn Zig
// 2. Read the input byte by byte to avoid multiple scans. This leads to more
//    checks for each byte (ie nine checks for each number), however, it's
//    memory efficient I guess.
const Calculator = struct {
    const debug_writer = struct {
        const Self = @This();
        pub fn print(_: Self, comptime _: []const u8, _: anytype) !void {
            return;
        }
    }{};

    fn maxStringLength(strings: []const []const u8) u8 {
        var max_len: u8 = 0;
        for (strings) |string| {
            if (string.len > max_len) {
                max_len = string.len;
            }
        }
        return max_len;
    }

    const possible_numbers = [_][]const u8{
        //          12345
        //          -----
        "one", //   one
        "two", //   two
        "three", // three
        "four", //  four
        "five", //  five
        "six", //   six
        "seven", // seven
        "eight", // eight
        "nine", //  nine
    };
    const maxNumWordLen = maxStringLength(&possible_numbers); // 5 as in "three" or "seven" or "eight"

    question_part: u8 = 2,
    bytes_read: u64 = 0,
    total_sum: u64 = 0,
    line_first_num: u64 = 0,
    line_last_num: u64 = 0,

    last_n_bytes: [maxNumWordLen]u8 = undefined,
    last_five_bytes_end_idx: u8 = 0,

    // For debugging only:
    debug: bool = false,
    current_line: [64]u8 = undefined,
    current_line_idx: u64 = 0,

    fn appendNumberToLastFive(self: *Calculator, new_number: u8) void {
        self.last_n_bytes[self.last_five_bytes_end_idx] = new_number;
        self.last_five_bytes_end_idx = (self.last_five_bytes_end_idx + 1) % @as(u8, @truncate(self.last_n_bytes.len));
    }
    fn resetLastFiveBytes(self: *Calculator) void {
        self.last_n_bytes = undefined;
    }

    fn getLastFiveBytes(self: *Calculator) [maxNumWordLen]u8 {
        var last_n_bytes: [maxNumWordLen]u8 = undefined;
        for (0..self.last_n_bytes.len) |i| {
            const idx = (self.last_five_bytes_end_idx + i) % @as(u8, @truncate(self.last_n_bytes.len));
            last_n_bytes[i] = self.last_n_bytes[idx];
        }
        return last_n_bytes;
    }
    fn printLastFiveBytes(self: *Calculator) !void {
        // TODO: can I join them?
        for (self.last_n_bytes) |byte| {
            if (byte == 0) {
                try debug_writer.print("{}", .{byte});
            } else {
                try debug_writer.print("{c}", .{byte});
            }
        }
        try debug_writer.print(" (end idx = {}) ", .{self.last_five_bytes_end_idx});
    }
    fn readBytes(self: *Calculator) !void {
        while (true) {
            const byte = stdin.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    try self.handleEndOfLine();
                    break;
                },
                else => {
                    try debug_writer.print("Ooops", .{});
                    return err;
                },
            };
            try self.handleByte(byte);
        }
    }

    fn handleByte(self: *Calculator, byte: u8) !void {
        if (self.debug) {
            self.current_line[self.current_line_idx] = byte;
            self.current_line_idx += 1;
        }

        self.bytes_read += 1;
        if (byte == '\n') {
            try self.handleEndOfLine();
            return;
        }

        try debug_writer.print("{c}: ", .{byte});

        if (self.question_part == 2) {
            self.appendNumberToLastFive(byte);
            try self.printLastFiveBytes();
        }

        if (byte >= '1' and byte <= '9') {
            const number = byte - '1' + 1;
            self.foundNumber(number);
            self.resetLastFiveBytes();
            try debug_writer.print("DIGIT:{c}={}", .{ byte, number });
        } else if (self.question_part == 2) {
            try self.trySpelledNumbers();
        }

        try debug_writer.print("\n", .{});
    }

    fn trySpelledNumbers(self: *Calculator) !void {
        for (0..possible_numbers.len) |index| {
            const word = possible_numbers[index];
            const word_len = word.len;
            if (std.mem.eql(u8, word, self.getLastFiveBytes()[self.last_n_bytes.len - word_len ..])) {
                self.foundNumber(@truncate(index + 1));
                try debug_writer.print("WORD:{s}={}", .{ word, index + 1 });
                break;
            }
        }
    }
    fn foundNumber(self: *Calculator, number: u8) void {
        // TODO: maybe look for the last number in the line from the end?
        // But then we'd have to read the whole line once and come back another time.
        // But still it might be less expensive than checking each byte with each of the nine numbers.
        if (self.line_first_num == 0) {
            self.line_first_num = number;
        }
        self.line_last_num = number;
    }
    fn handleEndOfLine(self: *Calculator) !void {
        const line_sum = 10 * self.line_first_num + self.line_last_num;
        try debug_writer.print("= 10 * {} + {} = {}\n", .{ self.line_first_num, self.line_last_num, line_sum });

        if (self.debug) {
            try debug_writer.print("Debug: full line: {s}\n\n", .{self.current_line[0..self.current_line_idx]});
            self.current_line_idx = 0;
        }

        self.total_sum += line_sum;
        self.line_first_num = 0;
        self.line_last_num = 0;
        self.bytes_read = 0;
        self.resetLastFiveBytes();
    }
};

pub fn main() !void {
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    var calculator = Calculator{};

    try calculator.readBytes();
    try stdout.print("total_sum: {}\n", .{calculator.total_sum});
    assert(54208 == calculator.total_sum);
}
