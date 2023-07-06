const std = @import("std");

const mibu = @import("mibu");

const events = mibu.events;

pub const Cell = struct {
    const Self = @This();
    content: []const u8 = " ",
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
};

pub const Rect = struct {
    const Self = @This();
    x: u32 = 0,
    y: u32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    allocator: std.mem.Allocator,
    label: []const u8 = "",

    fn drawBorder(self: *Self, buf: *Buf) void {
        var i: u32 = 0;
        var j: u32 = 0;
        while (i < self.h) : (i += 1) {
            j = 0;
            while (j < self.w) : (j += 1) {
                if (i == 0 and j == 0) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "┏";
                } else if (i == 0 and j == self.w - 1) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "┓";
                } else if (i == self.h - 1 and j == 0) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "┗";
                } else if (i == self.h - 1 and j == self.w - 1) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "┛";
                } else if (i == 0 or i == self.h - 1) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "━";
                } else if (j == 0 or j == self.w - 1) {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = "┃";
                } else {
                    buf.lines.items[(i + self.y) * buf.w + self.x + j].content = " ";
                }
            }
        }
    }

    fn drawLabel(self: *Self, buf: *Buf) !void {
        var x = buf.w * self.y + self.x;

        for (self.label, 0..) |c, i| {
            var s: []u8 = try self.allocator.alloc(u8, 1);
            @memcpy(s[0..], &[_]u8{c});
            buf.lines.items[x + i + 2].content = s;
        }
    }

    pub fn draw(self: *Self, buf: *Buf) !void {
        self.drawBorder(buf);
        try self.drawLabel(buf);
    }
};

pub const Input = struct {
    const Self = @This();
    x: u32 = 0,
    y: u32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    allocator: std.mem.Allocator,
    label: []const u8 = "",
    rect: ?Rect = null,
    content: std.ArrayList(u8) = undefined,

    pub fn init(x: u32, y: u32, w: u32, h: u32, label: []const u8, allocator: std.mem.Allocator) Input {
        return Input{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .allocator = allocator,
            .rect = Rect{ .x = x, .y = y, .h = h, .w = w, .label = label, .allocator = allocator },
            .content = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn drawContent(self: *Self, buf: *Buf) !void {
        for (self.content.items, 0..) |c, i| {
            var y = self.y + 1 + i / (self.w - 2);
            var x = buf.w * y + self.x + 1 + @rem(i, (self.w - 2));
            var s: []u8 = try self.allocator.alloc(u8, 1);
            @memcpy(s[0..], &[_]u8{c});
            buf.lines.items[x].content = s;
        }
    }

    pub fn draw(self: *Self, buf: *Buf) !void {
        try self.rect.?.draw(buf);
        try self.drawContent(buf);
    }

    pub fn handleEvent(self: *Self, event: events.Event) !void {
        switch (event) {
            .key => |k| switch (k) {
                .char => |c| {
                    try self.content.append(@truncate(u8, c));
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
