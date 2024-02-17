const std = @import("std");
const stdout = std.io.getStdOut().writer();

// playing with hashmaps
pub fn main() !void {
    var my_hash = std.StringHashMap(void).init(std.heap.page_allocator);

    try my_hash.put("one", void{});
    var x = my_hash.get("two");
    try stdout.print("x: {any}\n", .{x});
    try stdout.print("my_hash={}\n", .{my_hash});
}
