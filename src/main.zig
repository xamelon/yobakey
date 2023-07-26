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

    defer stdout.writer().print("Have a good day!", .{}) catch unreachable;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var size = try term.getSize(0);

    var buffer = try Buf.init(size.width, size.height, allocator);

    var input = PlaceholderInput.init(0, 3, 50, 20, "Your Input", allocator);

    var statsLabel = Label.init(0, 0, 50, 3, "Stats", "Hello my mini boy");

    try stdout.writer().print("Press Ctrl-Q to exit..\n\r", .{});
    try stdout.writer().print("{s}\n\r", .{clear.print.all});

    var statsBuf: [100]u8 = undefined;

    var timer = try Timer.start();

    const timestamp: u64 = @as(u64, @intCast(std.time.timestamp()));
    var xoshiro = std.rand.DefaultPrng.init(timestamp);
    var random = xoshiro.random();

    var file = try std.fs.cwd().openFile("words.txt", std.fs.File.OpenFlags{});
    var fileLen = try file.getEndPos();
    var content = try file.readToEndAlloc(allocator, fileLen);
    content = content[0 .. fileLen - 1];
    var delimeted = std.mem.splitAny(u8, content, " \n");

    var fileContent = std.ArrayList([]const u8).init(allocator);
    var word: ?[]const u8 = delimeted.first();
    while (word != null) : (word = delimeted.next()) {
        try fileContent.append(word.?);
    }
    random.shuffle([]const u8, fileContent.items);
    var newExercise = try std.mem.join(allocator, " ", fileContent.items);
    fileContent.deinit();
    input.placeholder = newExercise;

    while (true) {
        statsLabel.content = std.fmt.bufPrint(&statsBuf, "Mistakes: {d} Time: {d}", .{
            input.mistakesCount,
            10 - @as(i64, @intCast((timer.read() / 1000000000))),
        }) catch unreachable;

        input.draw(&buffer);
        statsLabel.draw(&buffer);
        try buffer.print(stdout.writer(), allocator);

        var event = try events.next(stdin);
        try input.handleEvent(event, &buffer);
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

    try mibu.clear.all(stdout.writer());
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
