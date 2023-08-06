const std = @import("std");

fn shuffleWords(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const timestamp: u64 = @as(u64, @intCast(std.time.timestamp()));
    var xoshiro = std.rand.DefaultPrng.init(timestamp);
    var random = xoshiro.random();
    var content = input[0 .. input.len - 1];
    var delimeted = std.mem.splitAny(u8, content, " \n");

    var fileContent = std.ArrayList([]const u8).init(allocator);
    var word: ?[]const u8 = delimeted.first();
    while (word != null) : (word = delimeted.next()) {
        try fileContent.append(word.?);
    }
    random.shuffle([]const u8, fileContent.items);

    return try std.mem.join(allocator, " ", fileContent.items);
}

pub fn loadIncluded(allocator: std.mem.Allocator) ![]const u8 {
    var originalFile = @embedFile("words.txt");
    return shuffleWords(originalFile, allocator);
}
