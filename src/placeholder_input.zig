const std = @import("std");

const Buf = @import("buf.zig").Buf;

const Rect = @import("rect.zig").Rect;

const mibu = @import("mibu");

const color = mibu.color;
const events = mibu.events;
const cursor = mibu.cursor;

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
    mistakesCount: u32 = 0,
    cursorPos: struct { x: u32, y: u32 } = .{ .x = 1, .y = 1 },

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
        self.updateCursorPos(buf) catch unreachable;
        self.drawContent(buf);
    }

    fn checkLastInput(self: *Self) void {
        var idx = self.content.items.len - 1;
        if (self.content.items[idx] != self.placeholder[idx]) {
            self.mistakesCount += 1;
        }
    }

    fn updateCursorPos(self: *Self, buf: *Buf) !void {
        _ = buf;
        var symbols = @as(u32, @intCast(self.content.items.len));
        var x: u32 = self.x + 1 + @rem(symbols, (self.w - 2));
        var y: u32 = self.y + 1 + symbols / (self.w - 2);
        self.cursorPos = .{ .x = x, .y = y };
    }

    pub fn getCursorPos(self: *Self) type {
        var symbols = @as(u32, @intCast(self.content.items.len));
        var x: u32 = self.x + 1 + @rem(symbols, (self.w - 2));
        var y: u32 = self.y + 1 + symbols / (self.w - 2);
        return .{ .x = x, .y = y };
    }

    pub fn handleEvent(self: *Self, event: events.Event, buf: *Buf) !void {
        switch (event) {
            .key => |k| switch (k) {
                .char => |c| {
                    if (self.content.items.len + 1 <= self.placeholder.len) {
                        try self.content.append(@as(u8, @truncate(c)));
                        self.checkLastInput();
                        try self.updateCursorPos(buf);
                    }
                },
                .delete => {
                    _ = self.content.pop();
                    try self.updateCursorPos(buf);
                },
                else => {},
            },
            else => {},
        }
    }
};
