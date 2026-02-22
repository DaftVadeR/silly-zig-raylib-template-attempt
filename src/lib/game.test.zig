const std = @import("std");
const game = @import("game.zig");
const plugin = @import("plugin.zig");

// Minimal no-op struct — used wherever the test doesn't care about callbacks.
const Noop = struct {
    pub fn update(_: *Noop) void {}
    pub fn draw(_: *Noop) void {}
    pub fn onLoad(_: *Noop, _: std.mem.Allocator) !void {}
};

var noop = Noop{};

fn noopPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(Noop, &noop, alloc);
}

fn noopGame(alloc: std.mem.Allocator) !game.Game {
    return game.Game.init(Noop, &noop, alloc);
}

test "game works with plugins" {
    var g = try noopGame(std.testing.allocator);
    defer g.deinit();

    try std.testing.expectEqual(@as(usize, 0), g.plugin_handler.plugins.items.len);

    try g.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    try std.testing.expectEqual(@as(usize, 1), g.plugin_handler.plugins.items.len);
}

test "plugins can have nested child plugins" {
    var g = try noopGame(std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    const first = &g.plugin_handler.plugins.items[0];
    try first.plugin_handler.addPlugin(try noopPlugin(std.testing.allocator));

    try std.testing.expectEqual(@as(usize, 1), first.plugin_handler.plugins.items.len);
}
