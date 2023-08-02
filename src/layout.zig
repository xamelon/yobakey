const std = @import("std");

const PlaceholderInput = @import("placeholder_input.zig").PlaceholderInput;
const Rect = @import("rect.zig").Rect;
const Label = @import("label.zig").Label;

const Buf = @import("buf.zig").Buf;

pub const LayoutChildren = union(enum) {
    rect: *Rect,
    input: *PlaceholderInput,
    label: *Label,
};

pub const Layout = struct {
    const Self = @This();

    children: std.ArrayList(LayoutChildren),

    pub fn init(allocator: std.mem.Allocator) Layout {
        return Layout{
            .children = std.ArrayList(LayoutChildren).init(allocator),
        };
    }

    pub fn addChild(self: *Self, child: LayoutChildren) !void {
        try self.children.append(child);
    }

    pub fn deinit(self: *Self) void {
        self.children.deinit();
    }

    pub fn draw(self: *Self, buf: *Buf) void {
        for (self.children.items) |child| {
            switch (child) {
                .rect => |r| r.draw(buf),
                .input => |i| i.draw(buf),
                .label => |l| l.draw(buf),
            }
        }
    }
};
