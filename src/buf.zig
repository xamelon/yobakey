const std = @import("std");

const color = @import("mibu").color;

pub const Cell = struct {
    const Self = @This();
    content: u21 = ' ',
    modifier: []const u8 = undefined,

    pub fn print(self: *Self, writer: anytype) !void {
        try writer.write().print("{s}{s}", .{ self.content, self.modifier });
    }
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

    pub fn print(self: *Self, writer: anytype) !void {
        for (self.lines.items) |word| {
            try writer.print("{s}{u}{s}", .{ word.modifier, word.content, color.print.reset });
        }
    }
};
