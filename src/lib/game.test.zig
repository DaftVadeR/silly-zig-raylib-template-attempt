const std = @import("std");
const game = @import("game.zig");
const plugin = @import("plugin.zig");

// Minimal no-op struct — used wherever the test doesn't care about callbacks.
const Noop = struct {
    pub fn update(_: *Noop) void {}
    pub fn draw(_: *Noop) void {}
};

var noop = Noop{};

fn noopPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(Noop, &noop, alloc);
}

fn noopGame(alloc: std.mem.Allocator) !game.Game {
    return game.Game.init(Noop, &noop, alloc);
}

test "Test game works with plugins" {
    var g = try noopGame(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 0), g.plugin_handler.plugins.items.len);

    try g.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    try std.testing.expectEqual(@as(usize, 1), g.plugin_handler.plugins.items.len);

    g.deinit();
}

test "Test plugins work with plugins" {
    var g = try noopGame(std.testing.allocator);
    try g.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    var firstPlugin = &g.plugin_handler.plugins.items[0];

    try firstPlugin.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    try std.testing.expectEqual(@as(usize, 1), firstPlugin.plugin_handler.plugins.items.len);

    g.deinit();
}
