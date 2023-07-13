const std = @import("std");

const Buf = @import("buf.zig").Buf;

const Rect = @import("rect.zig").Rect;

const color = @import("mibu").color;
const events = @import("mibu").events;
const cursor = @import("mibu").cursor;

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
            var ii: u32 = @as(u32, @intCast(i));
            var y: u32 = self.y + 1 + ii / (self.w - 2);
            var x: u32 = self.x + 1 + @rem(ii, (self.w - 2));
            lastX = x;
            lastY = y;
            buf.setCellContentChar(x, y, self.placeholder[i]);
            if (c == self.placeholder[i]) {
                buf.setCellModifier(x, y, color.print.fg(color.Color.black));
            } else {
                var fgColor = "\x1b[38;2;255;100;100m";
                buf.setCellModifier(x, y, fgColor);
            }
        }

        cursor.goTo(std.io.getStdOut().writer(), 0, 0) catch |err| {
            std.debug.print("{}", .{err});
        };
    }

    fn drawPlaceholder(self: *Self, buf: *Buf) void {
        var grayColor: []const u8 = "\x1b[38;2;200;200;200m";

        for (self.placeholder, 0..) |c, i| {
            var ii: u32 = @intCast(i);
            var y: u32 = self.y + 1 + ii / (self.w - 2);
            var x: u32 = self.x + 1 + @rem(ii, (self.w - 2));
            buf.setCellContentChar(x, y, c);
            buf.setCellModifier(x, y, grayColor);
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
                        try self.content.append(@as(u8, @truncate(c)));
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

    pub fn mistakesCount(self: *Self) u32 {
        var count: u32 = 0;
        for (self.content.items, 0..) |c, i| {
            if (c != self.placeholder[i]) {
                count += 1;
            }
        }
        return count;
    }
};
