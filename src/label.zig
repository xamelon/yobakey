const std = @import("std");

const Buf = @import("buf.zig").Buf;

const Rect = @import("rect.zig").Rect;

pub const Label = struct {
    const Self = @This();
    x: u32 = 0,
    y: u32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    rect: ?Rect = null,
    content: []const u8,

    pub fn init(x: u32, y: u32, w: u32, h: u32, label: []const u8, content: []const u8) Label {
        return Label{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .content = content,
            .rect = Rect{
                .x = x,
                .y = y,
                .h = h,
                .w = w,
                .label = label,
            },
        };
    }

    pub fn drawContent(self: *Self, buf: *Buf) void {
        for (self.content, 0..) |c, i| {
            var ii: u32 = @intCast(i);
            var y: u32 = self.y + 1 + ii / (self.w - 2);
            var x: u32 = self.x + 1 + @rem(ii, (self.w - 2));
            buf.setCellContentChar(x, y, c);
        }
    }

    pub fn draw(self: *Self, buf: *Buf) void {
        self.rect.?.draw(buf);
        self.drawContent(buf);
    }
};
