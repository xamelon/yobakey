const std = @import("std");

const mibu = @import("mibu");

const widget = @import("widget.zig");

const Buf = @import("buf.zig").Buf;
const Rect = @import("rect.zig").Rect;
const PlaceholderInput = @import("placeholder_input.zig").PlaceholderInput;
const Label = @import("label.zig").Label;

const term = mibu.term;
const events = mibu.events;
const clear = mibu.clear;
const cursor = mibu.cursor;
const color = mibu.color;

const Timer = std.time.Timer;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // stdout, not any debugging messages.
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    var raw_term = try term.enableRawMode(stdin.handle, .nonblocking);

    defer raw_term.disableRawMode() catch {};

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var size = try term.getSize(0);

    var buffer = try Buf.init(size.width, size.height, allocator);

    var input = PlaceholderInput.init(10, 30, 50, 20, "Your Input", allocator);
    input.placeholder = "hello hello boy";

    var statsLabel = Label.init(10, 27, 50, 3, "Stats", "Hello my mini boy");

    try stdout.writer().print("Press Ctrl-Q to exit..\n\r", .{});
    try stdout.writer().print("{s}\n\r", .{clear.print.all});

    var statsBuf: [100]u8 = undefined;

    var timer = try Timer.start();

    while (true) {
        statsLabel.content = std.fmt.bufPrint(&statsBuf, "Mistakes: {d} Time: {d}", .{
            input.mistakesCount(),
            30 - (timer.read() / 1000000000),
        }) catch unreachable;

        input.draw(&buffer);
        statsLabel.draw(&buffer);
        try buffer.print(stdout.writer());

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
