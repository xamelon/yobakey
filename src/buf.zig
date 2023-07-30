const std = @import("std");

const mibu = @import("mibu/src/main.zig");

const color = mibu.color;
const cursor = mibu.cursor;
const clear = mibu.clear;

pub const Cell = struct {
    const Self = @This();
    content: u21 = ' ',
    modifier: []const u8 = undefined,

    pub fn isEmpty(self: *Self) bool {
        return self.content == ' ' and self.modifier.len == 0;
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

    pub fn deinit(self: *Self) void {
        self.lines.deinit();
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

    pub fn print(self: *Self, prevBuf: *Buf, allocator: std.mem.Allocator) ![]const u8 {
        var output = std.ArrayList([]u8).init(allocator);

        var y: u32 = 0;
        var x: u32 = 0;
        while (x * y < self.h * self.w) {
            var cell = self.lines.items[x * y];
            var prevCell = prevBuf.lines.items[x * y];
            if (cell.content != prevCell.content) {
                var cellContent = try std.fmt.allocPrint(
                    allocator,
                    "{s}{s}{u}{s}",
                    .{
                        cursor.print.goTo(x + 1, y),
                        cell.modifier,
                        cell.content,
                        color.print.reset,
                    },
                );

                try output.append(cellContent);
            }

            if (x == self.w - 1) {
                x = 0;
                y = y + 1;
            } else {
                x = x + 1;
            }
        }

        var items = try output.toOwnedSlice();

        var content = try std.mem.concat(allocator, u8, items);

        output.deinit();
        allocator.free(items);

        return content;
    }
};

test "testing print buffer" {
    const allocator = std.testing.allocator;
    var buf = try Buf.init(2, 2, allocator);
    var buf2 = try Buf.init(2, 2, allocator);

    defer buf.deinit();
    defer buf2.deinit();

    buf.setCellContentChar(1, 1, 'c');

    const pprint = buf.print(&buf2, allocator) catch unreachable;
    allocator.free(pprint);
}
