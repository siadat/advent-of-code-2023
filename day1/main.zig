const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    // add some comment
    while (true) {
        // this function reads stdin one single byte at a type
        stdin.streamUntilDelimiter(stdout, '\n', null) catch |err| switch (err) {
            error.EndOfStream => return,
            else => return err,
        };
        try stdout.print("\n", .{});
    }
}
