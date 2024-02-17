const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const assert = std.debug.assert;
const TODO = unreachable;

const Color = enum {
    blue,
    green,
    red,
};

const Token = enum {
    GameWord,
    GameID,
    ColorCount,
    ColorWord,
};

test "test memory leak for ArrayList" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    var some_list = &list; // There will be a memory leak if you change this to `var some_list = list;`
    try some_list.append('q');
}

test "learning" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    defer std.log.warn("capacity: {d}\n", .{list.capacity});
    inline for (0..500) |_| try list.append('m');
}

test "let's see if blah" {
    const StringReader = struct {
        const Self = @This();
        line: []const u8, // TODO: why do I need const here? https://zig.news/kristoff/what-s-a-string-literal-in-zig-31e9 answer: because u8s in string literals are const
        index: u64 = 0,
        fn readByte(self: *Self) !u8 {
            if (self.index >= self.line.len) {
                return error.EndOfStream;
            }
            if (self.index == std.math.maxInt(@TypeOf(self.index))) {
                try stdout.print("self.index={d} and string length is {d}\n", .{ self.index, self.line.len });
                return error.StringIsTooLarge;
            }
            defer self.index += 1;
            return self.line[self.index];
        }
    };
    const test_cases = [_]struct { game: []const u8, want: u64 }{
        .{ .game = "Game 100: ", .want = 100 },
        .{ .game = "Game 100: 14 red\n\n", .want = 0 },
        .{ .game = "Game 100: 12 green", .want = 100 },
        .{ .game = 
        \\Game 98: 1 green, 9 red; 1 red, 2 green, 7 blue; 8 red, 1 blue; 6 red, 2 green; 1 green, 6 blue
        \\Game 99: 1 green, 2 red, 6 blue; 6 red, 1 green, 5 blue; 11 blue, 6 red; 11 red, 1 green; 1 green, 11 red, 9 blue
        \\Game 100: 12 green, 8 blue, 2 red; 7 blue, 14 red, 8 green; 14 red, 1 blue, 4 green
        , .want = 98 + 99 },
        .{ .game = 
        \\Game 100: 12 green, 8 blue, 2 red; 7 blue, 11 red, 8 green
        \\Game 1000: 13 red
        \\Game 200: 5 blue
        , .want = 100 + 200 },
        .{ .game = 
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
        , .want = 8 },
        .{ .game = "Game 100: 12 red; 13 green; 14 blue", .want = 100 },
        .{ .game = "Game 100: 12 red, 13 green, 14 blue", .want = 100 },
        .{ .game = "Game 100: 13 red", .want = 0 },
        .{ .game = "Game 100: 14 green", .want = 0 },
        .{ .game = "Game 100: 15 blue", .want = 0 },
        .{ .game = "Game 100: 12 green, 8 blue, 2 red; 7 blue, 14 red, 8 green; 14 red, 1 blue, 4 green", .want = 0 },
        .{ .game = "Game 100: 12 green, 8 blue, 2 red; 7 blue, 11 red, 8 green; 4 red, 1 blue, 4 green", .want = 100 },
    };
    for (test_cases, 0..) |test_case, index| {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();

        var reader = MainReader{
            .current_lit = &list,
        };
        var string_reader = StringReader{
            .line = test_case.game,
        };
        // @compileLog(@TypeOf(&string_reader));
        // TODO: why does passing a pointer not work? ie why `var s = &StringReader{.line="..."}; try reader.readBytes(s)` does't work. answer: because &SomeType{} returns a const pointer.
        const got = try reader.readBytes(&string_reader);
        if (got != test_case.want) {
            try stdout.print("index={d} got={d}, want={d}\n", .{ index, got, test_case.want });
        }
        assert(got == test_case.want);
    }
}

test "let's see if I can use an ArrayList as a string" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var list = std.ArrayList(u8).init(gpa.allocator());
    defer {
        list.deinit();
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.log.warn("There is memory leak\n", .{});
        }
    }

    var reader = MainReader{
        .current_lit = &list,
    };
    try reader.current_lit.append('o');
    try reader.current_lit.append('k');
    assert(std.mem.eql(u8, "ok", reader.current_lit.items));
}

const MainReader = struct {
    // stdin: std.io.Reader(*MainReader, std.os.ReadError, readFn),
    current_type: Token = Token.GameWord,

    current_lit: *std.ArrayList(u8), // .init(std.heap.page_allocator),

    max_red: u64 = 12,
    max_green: u64 = 13,
    max_blue: u64 = 14,

    current_cube_count: u64 = 0,
    current_game_id: u64 = 0,

    valid_game: bool = true,

    total_sum: u64 = 0,

    fn readFn(_: *MainReader, _: []u8) std.os.ReadError!usize {}

    fn handleByte(self: *MainReader, byte: u8) !void {
        switch (byte) {
            ';', ':', ',', ' ' => try self.handleBreak(),
            '\n' => try self.handleEndOfGame(),
            '0'...'9' => try self.handleAlphabet(byte),
            'a'...'z' => try self.handleAlphabet(byte),
            'A'...'Z' => try self.handleAlphabet(byte),
            else => {
                try stdout.print("Saw {any}='{c}'\n", .{ byte, byte });
                unreachable;
            },
        }
    }
    fn handleBreak(self: *MainReader) !void {
        if (self.current_lit.items.len == 0) {
            return;
        }
        if (!self.valid_game) {
            return;
        }

        switch (self.current_type) {
            Token.GameWord => {
                self.current_type = Token.GameID;
            },
            Token.GameID => {
                self.current_game_id = try std.fmt.parseInt(u64, self.current_lit.items, 10);
                self.current_type = Token.ColorCount;
            },
            Token.ColorCount => {
                self.current_cube_count = try std.fmt.parseInt(u64, self.current_lit.items, 10);
                self.current_type = Token.ColorWord;
            },
            Token.ColorWord => {
                switch (std.meta.stringToEnum(Color, self.current_lit.items).?) {
                    .blue => if (self.current_cube_count > self.max_blue) {
                        self.valid_game = false;
                        // try stdout.print("Game {}: is invalid because {d} blue > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_blue });
                    },
                    .green => if (self.current_cube_count > self.max_green) {
                        self.valid_game = false;
                        // try stdout.print("Game {}: is invalid because {d} green > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_green });
                    },
                    .red => if (self.current_cube_count > self.max_red) {
                        self.valid_game = false;
                        // try stdout.print("Game {}: is invalid because {d} red > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_red });
                    },
                }
                self.current_type = Token.ColorCount;
            },
        }
        self.current_lit.clearRetainingCapacity();
    }
    fn handleAlphabet(self: *MainReader, byte: u8) !void {
        if (!self.valid_game) {
            // try stdout.print("Char '{c}', valid_game={}\n", .{ byte, self.valid_game });
            return;
        }
        try self.current_lit.append(byte);
    }
    fn handleEndOfGame(self: *MainReader) !void {
        try self.handleBreak();
        if (self.valid_game) {
            self.total_sum += self.current_game_id;
            // try stdout.print("Game {} was valid, adding {d}, getting {d}\n", .{ self.current_game_id, self.current_game_id, self.total_sum });
        }
        self.current_type = Token.GameWord;
        self.valid_game = true;
        self.current_cube_count = 0;
        self.current_lit.clearRetainingCapacity();
        // setting current_game_id to 0 so that multiple calls to
        // this function are idempotent
        self.current_game_id = 0;
    }
    fn handleEndOfFile(self: *MainReader) !void {
        try self.handleEndOfGame();
    }
    fn readBytes(self: *MainReader, reader: anytype) !@TypeOf(self.total_sum) { // TODO: AWHHHHWWWHHHAT WOW I LOVE @TypeOf
        //defer self.current_lit.deinit(); Commented because we don't own this pointer, so we shouldn't free it.
        self.current_type = Token.GameWord;
        while (true) {
            const byte = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    try self.handleEndOfFile();
                    break;
                },
                else => {
                    try stdout.print("Got error: {?}", .{err});
                    return err;
                },
            };
            try self.handleByte(byte);
        }
        return self.total_sum;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var list = std.ArrayList(u8).init(gpa.allocator());
    defer {
        list.deinit();
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.log.warn("There is memory leak\n", .{});
        }
    }
    var reader = MainReader{
        .current_lit = &list,
    };
    const total_sum = try reader.readBytes(stdin);
    try stdout.print("total_sum={d}\n", .{total_sum});
}
