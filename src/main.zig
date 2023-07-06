const std = @import("std");

const mibu = @import("mibu");

const widget = @import("widget.zig");

const Buf = @import("rect.zig").Buf;
const Rect = @import("rect.zig").Rect;
const Input = @import("rect.zig").Input;

const term = mibu.term;
const events = mibu.events;
const clear = mibu.clear;
const cursor = mibu.cursor;
const color = mibu.color;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // stdout, not any debugging messages.
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    var raw_term = try term.enableRawMode(stdin.handle, .blocking);

    defer raw_term.disableRawMode() catch {};

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var size = try term.getSize(0);

    var buffer = try Buf.init(size.width, size.height, allocator);

    var rect = Rect{ .w = 50, .h = 20, .x = 10, .y = 10, .label = "Exercise", .allocator = allocator };

    var input = Input.init(10, 30, 50, 20, "Your Input", allocator);

    try stdout.writer().print("Press Ctrl-Q to exit..\n\r", .{});
    try stdout.writer().print("{s}\n\r", .{clear.print.all});
    while (true) {
        try rect.draw(&buffer);
        try input.draw(&buffer);

        try stdout.writer().print("{s}", .{cursor.print.goTo(0, 0)});

        for (buffer.lines.items) |word| {
            try stdout.writer().print("{s}", .{word.content});
            try color.resetAll(stdout.writer());
        }
        var event = try events.next(stdin);
        try input.handleEvent(event);
        switch (event) {
            .key => |k| switch (k) {
                .ctrl => |c| switch (c) {
                    'c' => break,
                    else => {},
                },
                else => {},
            },
            else => {},
        }
    }

    try stdout.writer().print("Term size: {d} {d}", .{ size.width, size.height });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
