const std = @import("std");

const mibu = @import("mibu");

const events = mibu.events;
const color = mibu.color;
const cursor = mibu.cursor;

const Buf = @import("buf.zig").Buf;

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
            buf.setCellContentChar(self.x + @as(u32, @intCast(i)) + 2, self.y, c);
            // try buf.lines.items[x + i + 2].setCharContent(c);
        }
    }

    pub fn draw(self: *Self, buf: *Buf) void {
        self.drawBorder(buf);
        self.drawLabel(buf);
    }
};
