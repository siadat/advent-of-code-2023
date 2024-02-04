const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const assert = std.debug.assert;

const Calculator = struct {
    question_part: u8 = 2,
    bytes_read: u64 = 0,
    total_sum: u64 = 0,
    line_first_num: u64 = 0,
    line_last_num: u64 = 0,
    last_five_bytes: [5]u8 = [_]u8{ 0, 0, 0, 0, 0 },
    possible_numbers: [9][]const u8 = [9][]const u8{
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    },

    // For debugging only:
    debug: bool = false,
    current_line: [64]u8 = undefined,
    current_line_idx: u64 = 0,

    fn appendNumberToLastFive(self: *Calculator, new_number: u8) void {
        // TODO: No need to actually shift|rotate the array, just keep track of the index
        for (1..self.last_five_bytes.len) |index| {
            self.last_five_bytes[index - 1] = self.last_five_bytes[index];
        }
        self.last_five_bytes[self.last_five_bytes.len - 1] = new_number;
    }
    fn resetLastFiveBytes(self: *Calculator) void {
        self.last_five_bytes = [_]u8{ 0, 0, 0, 0, 0 };
    }

    fn printLastFiveBytes(self: *Calculator) !void {
        // TODO: can I join them?
        for (self.last_five_bytes) |byte| {
            if (byte == 0) {
                try stdout.print("{}", .{byte});
            } else {
                try stdout.print("{c}", .{byte});
            }
        }
        try stdout.print(" ", .{});
    }
    fn readBytes(self: *Calculator) !void {
        while (true) {
            const byte = stdin.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    try self.handleEndOfLine();
                    break;
                },
                else => {
                    try stdout.print("Ooops", .{});
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

        try stdout.print("{c}: ", .{byte});

        if (self.question_part == 2) {
            self.appendNumberToLastFive(byte);
            try self.printLastFiveBytes();
        }

        if (byte >= '1' and byte <= '9') {
            const number = byte - '1' + 1;
            self.foundNumber(number);
            self.resetLastFiveBytes();
            try stdout.print("DIGIT:{c}={}", .{ byte, number });
        } else if (self.question_part == 2) {
            try self.trySpelledNumbers();
        }

        try stdout.print("\n", .{});
    }

    fn trySpelledNumbers(self: *Calculator) !void {
        for (0..self.possible_numbers.len) |index| {
            const word = self.possible_numbers[index];
            const word_len = word.len;
            if (std.mem.eql(u8, word, self.last_five_bytes[self.last_five_bytes.len - word_len ..])) {
                self.foundNumber(@truncate(index + 1));
                try stdout.print("WORD:{s}={}", .{ word, index + 1 });
                break;
            }
        }
    }
    fn foundNumber(self: *Calculator, number: u8) void {
        if (self.line_first_num == 0) {
            self.line_first_num = number;
        }
        self.line_last_num = number;
    }
    fn handleEndOfLine(self: *Calculator) !void {
        if (self.last_five_bytes.len > self.bytes_read) {
            for (0..self.last_five_bytes.len - self.bytes_read + 1) |_| {
                self.appendNumberToLastFive(0);
            }
            try self.printLastFiveBytes();
            try stdout.print("\n", .{});
        }

        const line_sum = 10 * self.line_first_num + self.line_last_num;
        try stdout.print("= 10 * {} + {} = {}\n", .{ self.line_first_num, self.line_last_num, line_sum });

        if (self.debug) {
            try stdout.print("Debug: full line: {s}\n\n", .{self.current_line[0..self.current_line_idx]});
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
