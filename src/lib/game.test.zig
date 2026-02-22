const std = @import("std");
const game = @import("game.zig");

// Used for tests that dont test the initial bootstrapping process
fn getGame() !game.Game {
    var g = try game.Game.init(std.testing.allocator);

    try g.plugin_handler.addPlugin(
        try game.Plugin.init(g.allocator),
    );

    return g;
}

test "Test game works with plugins" {
    const gpa = std.testing.allocator;

    var g = try game.Game.init(gpa);

    try std.testing.expectEqual(
        @as(usize, 0),
        g.plugin_handler.plugins.items.len,
    );

    try g.plugin_handler.addPlugin(try game.Plugin.init(gpa));

    try std.testing.expectEqual(
        @as(usize, 1),
        g.plugin_handler.plugins.items.len,
    );

    g.deinit();
}

test "Test plugins work with plugins" {
    var g = try getGame();

    try std.testing.expectEqual(
        @as(usize, 1),
        g.plugin_handler.plugins.items.len,
    );

    try std.testing.expectEqual(
        g.plugin_handler.plugins.items.len,
        @as(usize, 1),
    );

    var firstPlugin = &g.plugin_handler.plugins.items[0];

    // TODO: add convenience methods
    try firstPlugin.plugin_handler.addPlugin(
        try game.Plugin.init(g.allocator),
    );

    try std.testing.expectEqual(
        @as(usize, 1),
        firstPlugin.plugin_handler.plugins.items.len,
    );

    // Should clean up ALLLLL
    g.deinit();
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
