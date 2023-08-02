const std = @import("std");

const mibu = @import("mibu/src/main.zig");

const Buf = @import("buf.zig").Buf;
const Rect = @import("rect.zig").Rect;
const PlaceholderInput = @import("placeholder_input.zig").PlaceholderInput;
const Label = @import("label.zig").Label;
const layout = @import("layout.zig");

const term = mibu.term;
const events = mibu.events;
const clear = mibu.clear;
const cursor = mibu.cursor;
const color = mibu.color;

const Timer = std.time.Timer;

pub const AppState = struct {
    cursorPos: struct { x: u32, y: u32 } = .{ .x = 0, .y = 0 },
};

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

    var buffer1 = try Buf.init(size.width, size.height, allocator);
    var buffer2 = try Buf.init(size.width, size.height, allocator);

    var input = PlaceholderInput.init(0, 3, 50, 20, "Your Input", allocator);

    var statsLabel = Label.init(0, 0, 50, 3, "Stats", "Hello my mini boy");

    try stdout.writer().print("Press Ctrl-Q to exit..\n\r", .{});
    try stdout.writer().print("{s}", .{clear.print.all});

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

    var appState = AppState{};

    var currentBuffer: *Buf = &buffer1;
    var prevBuffer: *Buf = &buffer2;

    var window = layout.Layout.init(allocator);

    try window.addChild(layout.LayoutChildren{ .label = &statsLabel });
    try window.addChild(layout.LayoutChildren{ .input = &input });

    while (true) {
        statsLabel.content = std.fmt.bufPrint(&statsBuf, "Mistakes: {d} Time: {d}", .{
            input.mistakesCount,
            10 - @as(i64, @intCast((timer.read() / 1000000000))),
        }) catch unreachable;

        appState.cursorPos = .{ .x = input.cursorPos.x, .y = input.cursorPos.y };

        window.draw(currentBuffer);

        try drawBuffer(
            stdout.writer(),
            currentBuffer,
            prevBuffer,
            &appState,
        );

        if (currentBuffer == &buffer1) {
            currentBuffer = &buffer2;
            prevBuffer = &buffer1;
        } else {
            currentBuffer = &buffer1;
            prevBuffer = &buffer2;
        }

        var event = try events.next(stdin);
        try input.handleEvent(event, currentBuffer);
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

fn drawBuffer(
    writer: anytype,
    buf: *Buf,
    prevBuffer: *Buf,
    appState: *AppState,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    const bufContent = try buf.print(prevBuffer, allocator);

    try writer.print("{s}{s}{s}{s}{s}", .{
        cursor.print.goTo(1, 1),
        cursor.print.hide(),
        bufContent,
        cursor.print.show(),
        cursor.print.goTo(appState.cursorPos.x + 1, appState.cursorPos.y + 1),
    });

    arena.deinit();
}
