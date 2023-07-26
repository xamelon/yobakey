const std = @import("std");

const mibu = @import("mibu");

const color = mibu.color;
const cursor = mibu.cursor;
const clear = mibu.clear;

pub const Cell = struct {
    const Self = @This();
    content: u21 = ' ',
    modifier: []const u8 = undefined,
};

pub const Buf = struct {
    const Self = @This();
    h: u32,
    w: u32,
    lines: std.ArrayList(Cell),

    pub fn init(w: u32, h: u32, allocator: std.mem.Allocator) !Self {
        var buf = Buf{
            .w = w,
            .h = h,
            .lines = std.ArrayList(Cell).init(allocator),
        };

        try buf.lines.appendNTimes(Cell{}, h * w);

        return buf;
    }

    pub fn setCellContentChar(self: *Self, x: u32, y: u32, content: u8) void {
        var row = self.w * y;
        var col = x;
        self.lines.items[row + col].content = content;
    }

    pub fn setCellContentString(self: *Self, x: u32, y: u32, content: []const u8) void {
        var row = self.w * y;
        var col = x;
        if (std.unicode.utf8Decode(content)) |value| {
            self.lines.items[row + col].content = value;
        } else |err| {
            self.lines.items[row + col].content = ' ';
            std.debug.print("{}", .{err});
        }
    }

    pub fn setCellModifier(self: *Self, x: u32, y: u32, modifier: []const u8) void {
        const row = self.w * y;
        const col = x;

        self.lines.items[row + col].modifier = modifier;
    }

    pub fn print(self: *Self, allocator: std.mem.Allocator) ![]const u8 {
        var output = std.ArrayList([]const u8).init(allocator);

        for (self.lines.items) |word| {
            var content = try std.fmt.allocPrint(allocator, "{s}{u}{s}", .{ word.modifier, word.content, color.print.reset });

            try output.append(content);
        }

        var content = try std.mem.concat(allocator, u8, output.items);

        output.deinit();

        return content;
    }
};
