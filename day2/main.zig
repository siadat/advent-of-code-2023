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

test "test one game" {
    const line = "Game 100: 12 green, 8 blue, 2 red; 7 blue, 14 red, 8 green; 14 red, 1 blue, 4 green";
    _ = line;
}

test "let's see if I can use an ArrayList as a string" {
    var reader = MainReader{
        .current_lit = std.ArrayList(u8).init(std.heap.page_allocator),
    };
    try reader.current_lit.append('o');
    try reader.current_lit.append('k');
    try stdout.print("It works: '{s}'\n", .{reader.current_lit.items});
    assert(std.mem.eql(u8, "ok", reader.current_lit.items));
}

const MainReader = struct {
    // stdin: std.io.Reader(*MainReader, std.os.ReadError, readFn),
    current_type: Token = Token.GameWord,

    current_lit: std.ArrayList(u8), // .init(std.heap.page_allocator),

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
            else => unreachable,
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
                        try stdout.print("Game {}: is invalid because {d} blue > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_blue });
                    },
                    .green => if (self.current_cube_count > self.max_green) {
                        self.valid_game = false;
                        try stdout.print("Game {}: is invalid because {d} green > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_green });
                    },
                    .red => if (self.current_cube_count > self.max_red) {
                        self.valid_game = false;
                        try stdout.print("Game {}: is invalid because {d} red > {d}\n", .{ self.current_game_id, self.current_cube_count, self.max_red });
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
            try stdout.print("Game {} was valid, adding {d}, getting {d}\n", .{ self.current_game_id, self.current_game_id, self.total_sum });
            // setting current_game_id to 0 so that multiple calls to
            // this function are idempotent
            self.current_game_id = 0;
        }
        self.current_type = Token.GameWord;
        self.valid_game = true;
        self.current_cube_count = 0;
        self.current_lit.clearRetainingCapacity();
    }
    fn handleEndOfFile(self: *MainReader) !void {
        try self.handleEndOfGame();
        try stdout.print("total_sum={d}\n", .{self.total_sum});
    }
    fn readBytes(self: *MainReader, reader: anytype) !void {
        defer self.current_lit.deinit();

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
    }
};

pub fn main() !void {
    var reader = MainReader{
        .current_lit = std.ArrayList(u8).init(std.heap.page_allocator),
    };
    try reader.readBytes(stdin);
}
