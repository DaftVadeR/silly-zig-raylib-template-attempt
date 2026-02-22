const std = @import("std");
const game = @import("game.zig");
const plugin = @import("plugin.zig");

// ------------------------------------------------------------
// File-scoped counters — reset at the top of each test
// ------------------------------------------------------------

var game_update_count: usize = 0;
var game_draw_count: usize = 0;
var plugin_a_update_count: usize = 0;
var plugin_a_draw_count: usize = 0;
var plugin_b_update_count: usize = 0;
var plugin_b_draw_count: usize = 0;
var child_update_count: usize = 0;
var child_draw_count: usize = 0;

// ------------------------------------------------------------
// Stub structs — one per counter pair, each with update/draw
// ------------------------------------------------------------

const GameRoot = struct {
    pub fn update(_: *GameRoot) void {
        game_update_count += 1;
    }
    pub fn draw(_: *GameRoot) void {
        game_draw_count += 1;
    }
};

const PluginA = struct {
    pub fn update(_: *PluginA) void {
        plugin_a_update_count += 1;
    }
    pub fn draw(_: *PluginA) void {
        plugin_a_draw_count += 1;
    }
};

const PluginB = struct {
    pub fn update(_: *PluginB) void {
        plugin_b_update_count += 1;
    }
    pub fn draw(_: *PluginB) void {
        plugin_b_draw_count += 1;
    }
};

const ChildPlugin = struct {
    pub fn update(_: *ChildPlugin) void {
        child_update_count += 1;
    }
    pub fn draw(_: *ChildPlugin) void {
        child_draw_count += 1;
    }
};

var game_root = GameRoot{};
var plugin_a = PluginA{};
var plugin_b = PluginB{};
var child_plugin = ChildPlugin{};

// ------------------------------------------------------------
// Tests
// ------------------------------------------------------------

test "game update and draw call their own callbacks" {
    game_update_count = 0;
    game_draw_count = 0;

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), game_update_count);
    try std.testing.expectEqual(@as(usize, 1), game_draw_count);
}

test "game update and draw propagate to plugins" {
    game_update_count = 0;
    game_draw_count = 0;
    plugin_a_update_count = 0;
    plugin_a_draw_count = 0;
    plugin_b_update_count = 0;
    plugin_b_draw_count = 0;

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));
    try g.addPlugin(try plugin.Plugin.init(PluginB, &plugin_b, std.testing.allocator));

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), game_update_count);
    try std.testing.expectEqual(@as(usize, 1), game_draw_count);
    try std.testing.expectEqual(@as(usize, 2), plugin_a_update_count);
    try std.testing.expectEqual(@as(usize, 2), plugin_b_update_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_a_draw_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_b_draw_count);
}

test "nested plugin update and draw propagate recursively" {
    game_update_count = 0;
    game_draw_count = 0;
    plugin_a_update_count = 0;
    plugin_a_draw_count = 0;
    child_update_count = 0;
    child_draw_count = 0;

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));

    const first = &g.plugin_handler.plugins.items[0];
    try first.plugin_handler.addPlugin(
        try plugin.Plugin.init(ChildPlugin, &child_plugin, std.testing.allocator),
    );

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), game_update_count);
    try std.testing.expectEqual(@as(usize, 1), game_draw_count);
    try std.testing.expectEqual(@as(usize, 2), plugin_a_update_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_a_draw_count);
    try std.testing.expectEqual(@as(usize, 2), child_update_count);
    try std.testing.expectEqual(@as(usize, 1), child_draw_count);
}
