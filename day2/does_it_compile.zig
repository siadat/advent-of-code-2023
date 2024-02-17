// https://zig.news/kristoff/what-s-a-string-literal-in-zig-31e9
const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const got = ohno(); // ohno returns a pointer to garbage memory
    try stdout.print("got {any}\n", .{got});
}

fn ohno() []const u8 {
    const foo = [4]u8{ 'o', 'h', 'n', 'o' };
    return &foo; // oh no, the memory where foo is stored
    // will be reclaimed as soon as we return!
}
