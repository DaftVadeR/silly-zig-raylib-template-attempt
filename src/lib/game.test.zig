const std = @import("std");
const game = @import("game.zig");

test "Test game works with plugins" {
    const gpa = std.testing.allocator;

    var g = try game.Game.init(gpa);

    try std.testing.expectEqual(
        @as(usize, 10),
        g.plugin_handler.plugins_allocated,
    );

    try std.testing.expectEqual(
        @as(usize, 0),
        g.plugin_handler.plugins_added,
    );

    try g.plugin_handler.addPlugin(try game.Plugin.init(gpa));

    try std.testing.expectEqual(
        @as(usize, 10),
        g.plugin_handler.plugins_allocated,
    );

    try std.testing.expectEqual(
        @as(usize, 1),
        g.plugin_handler.plugins_added,
    );

    try g.deinit();
}

// var list: std.ArrayList(i32) = .empty;
// defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!

// try list.append(gpa, 42);

// const allocator = gpa.allocator();

//
// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
