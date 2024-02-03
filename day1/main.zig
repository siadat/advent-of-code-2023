const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    // var buf = [3]u8{ 0, 0, 0 };
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    const count = try stdin.readAllArrayList(&buf, 22110);
    try stdout.print("read {} bytes, they are {any}", .{ count, buf.items });
}
