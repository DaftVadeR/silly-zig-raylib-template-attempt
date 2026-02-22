const std = @import("std");
const game = @import("game.zig");
const plugin = @import("plugin.zig");
const plugin_handler = @import("plugin-handler.zig");

const TestPlugin = struct {
    num_draw_calls: u16,
    num_update_calls: u16,

    fn incrementDrawCount(self: *TestPlugin) void {
        self.num_draw_calls += 1;
    }

    fn incrementUpdateCount(self: *TestPlugin) void {
        self.num_update_calls += 1;
    }

    pub fn init() TestPlugin {
        return .{
            .num_draw_calls = 0,
            .num_update_calls = 0,
        };
    }

    // reuse for tests
    pub fn onDraw(self: *TestPlugin) *fn (self: *TestPlugin) void {
        self.incrementDrawCount();
    }

    // reuse for tests
    pub fn onUpdate(self: *TestPlugin) *fn (self: *TestPlugin) void {
        self.incrementUpdateCount();
    }

    // Used for tests that dont test the initial bootstrapping process
    pub fn getGame(self: *TestPlugin) !game.Game {
        var g = try game.Game.init(
            std.testing.allocator,
            *self.onUpdate,
            *self.onDraw,
        );

        try g.plugin_handler.addPlugin(
            try plugin.Plugin.init(
                g.allocator,
                self.onUpdate,
                self.onDraw,
            ),
        );

        return g;
    }
};

test "Test plugin handler update and draw get called" {
    var t = TestPlugin.init();

    var g = try t.getGame();

    try std.testing.expectEqual(
        @as(usize, 1),
        g.plugin_handler.plugins.items.len,
    );

    for (0..10) |_| {
        g.update();
    }

    try std.testing.expectEqual(
        @as(usize, 10),
        t.num_update_calls,
    );

    for (0..10) |_| {
        g.draw();
    }

    try std.testing.expectEqual(
        @as(usize, 10),
        t.num_draw_calls,
    );

    // g.plugins[0].
    //
    //
    // try g.plugin_handler.addPlugin(try game.Plugin.init(gpa));
    //
    // try std.testing.expectEqual(
    //     @as(usize, 1),
    //     g.plugin_handler.plugins.items.len,
    // );

    g.deinit();
}

// test "Test plugins work with plugins" {
//     var g = try getGame();
//
//     try std.testing.expectEqual(
//         @as(usize, 1),
//         g.plugin_handler.plugins.items.len,
//     );
//
//     try std.testing.expectEqual(
//         g.plugin_handler.plugins.items.len,
//         @as(usize, 1),
//     );
//
//     var firstPlugin = &g.plugin_handler.plugins.items[0];
//
//     // TODO: add convenience methods
//     try firstPlugin.plugin_handler.addPlugin(
//         try game.Plugin.init(g.allocator),
//     );
//
//     try std.testing.expectEqual(
//         @as(usize, 1),
//         firstPlugin.plugin_handler.plugins.items.len,
//     );
//
//     // Should clean up ALLLLL
//     g.deinit();
// }

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
