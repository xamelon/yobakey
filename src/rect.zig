const std = @import("std");

const mibu = @import("mibu");

const events = mibu.events;
const color = mibu.color;
const cursor = mibu.cursor;

pub const Cell = struct {
    const Self = @This();
    content: u21 = ' ',
    modifier: []const u8 = mibu.utils.csi ++ mibu.utils.reset_all,

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

pub const Rect = struct {
    const Self = @This();
    x: u32 = 0,
    y: u32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    label: []const u8 = "",

    fn drawBorder(self: *Self, buf: *Buf) void {
        var i: u32 = 0;
        var j: u32 = 0;
        while (i < self.h) : (i += 1) {
            j = 0;
            while (j < self.w) : (j += 1) {
                if (i == 0 and j == 0) {
                    buf.setCellContentString(self.x + j, i + self.y, "┏");
                } else if (i == 0 and j == self.w - 1) {
                    buf.setCellContentString(self.x + j, i + self.y, "┓");
                } else if (i == self.h - 1 and j == 0) {
                    buf.setCellContentString(self.x + j, i + self.y, "┗");
                } else if (i == self.h - 1 and j == self.w - 1) {
                    buf.setCellContentString(self.x + j, i + self.y, "┛");
                } else if (i == 0 or i == self.h - 1) {
                    buf.setCellContentString(self.x + j, i + self.y, "━");
                } else if (j == 0 or j == self.w - 1) {
                    buf.setCellContentString(self.x + j, i + self.y, "┃");
                } else {
                    buf.setCellContentString(self.x + j, i + self.y, " ");
                }
            }
        }
    }

    fn drawLabel(self: *Self, buf: *Buf) void {
        var x = buf.w * self.y + self.x;
        _ = x;

        for (self.label, 0..) |c, i| {
            buf.setCellContentChar(self.x + @intCast(u32, i) + 2, self.y, c);
            // try buf.lines.items[x + i + 2].setCharContent(c);
        }
    }

    pub fn draw(self: *Self, buf: *Buf) void {
        self.drawBorder(buf);
        self.drawLabel(buf);
    }
};

pub const PlaceholderInput = struct {
    const Self = @This();
    x: u32 = 0,
    y: u32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    allocator: std.mem.Allocator,
    label: []const u8 = "",
    rect: ?Rect = null,
    placeholder: []const u8 = "",
    content: std.ArrayList(u8) = undefined,

    pub fn init(x: u32, y: u32, w: u32, h: u32, label: []const u8, allocator: std.mem.Allocator) PlaceholderInput {
        return PlaceholderInput{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .allocator = allocator,
            .rect = Rect{
                .x = x,
                .y = y,
                .h = h,
                .w = w,
                .label = label,
            },
            .content = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn drawContent(self: *Self, buf: *Buf) void {
        var lastX: u32 = 0;
        var lastY: u32 = 0;
        for (self.content.items, 0..) |c, i| {
            var ii: u32 = @intCast(u32, i);
            var y: u32 = self.y + 1 + ii / (self.w - 2);
            var x: u32 = self.x + 1 + @rem(ii, (self.w - 2));
            lastX = x;
            lastY = y;
            buf.setCellContentChar(x, y, c);
            if (c == self.placeholder[i]) {
                buf.setCellModifier(x, y, color.print.fg(color.Color.black));
            } else {
                buf.setCellModifier(x, y, color.print.bg(color.Color.red));
            }
        }

        std.debug.print("lastX: {d} lastY: {d}", .{ lastX, lastY });
        cursor.goTo(std.io.getStdOut().writer(), 0, 0) catch |err| {
            std.debug.print("{}", .{err});
        };
    }

    fn drawPlaceholder(self: *Self, buf: *Buf) void {
        for (self.placeholder, 0..) |c, i| {
            var ii: u32 = @intCast(u32, i);
            var y: u32 = self.y + 1 + ii / (self.w - 2);
            var x: u32 = self.x + 1 + @rem(ii, (self.w - 2));
            buf.setCellContentChar(x, y, c);
            buf.setCellModifier(x, y, color.print.fg(color.Color.default));
        }
    }

    pub fn draw(self: *Self, buf: *Buf) void {
        self.rect.?.draw(buf);
        self.drawPlaceholder(buf);
        self.drawContent(buf);
    }

    pub fn handleEvent(self: *Self, event: events.Event) !void {
        switch (event) {
            .key => |k| switch (k) {
                .char => |c| {
                    if (self.content.items.len + 1 <= self.placeholder.len) {
                        try self.content.append(@truncate(u8, c));
                    }
                },
                .delete => {
                    _ = self.content.pop();
                },
                else => {},
            },
            else => {},
        }
    }
};
