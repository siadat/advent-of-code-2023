const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const assert = std.debug.assert;

pub fn main() !void {
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    var total_sum: u64 = 0;
    var line_first_num: u64 = 0;
    var line_last_num: u64 = 0;

    while (true) {
        const byte = stdin.readByte() catch |err| switch (err) {
            error.EndOfStream => {
                try stdout.print("{}+{}\n\n", .{ line_first_num, line_last_num });
                total_sum += 10 * line_first_num + line_last_num;
                line_first_num = 0;
                line_last_num = 0;
                break;
            },
            else => {
                try stdout.print("Ooops", .{});
                return err;
            },
        };

        try stdout.print("{c}:{}\n", .{ byte, byte });

        if (byte == '\n') {
            try stdout.print("{}+{}\n\n", .{ line_first_num, line_last_num });
            total_sum += 10 * line_first_num + line_last_num;
            line_first_num = 0;
            line_last_num = 0;
        } else if (byte >= '1' and byte <= '9') {
            const value = byte - '1' + 1;
            if (line_first_num == 0) {
                line_first_num = value;
            }
            line_last_num = value;
        }
    }
    try stdout.print("total_sum: {}\n", .{total_sum});
    assert(54940 == total_sum);
}
