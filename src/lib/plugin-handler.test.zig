const std = @import("std");
const game = @import("game.zig");
const plugin = @import("plugin.zig");

// ------------------------------------------------------------
// File-scoped counters — each test resets them before use
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
// Callback functions — each just increments its counter
// ------------------------------------------------------------

fn gameUpdate() void {
    game_update_count += 1;
}
fn gameDraw() void {
    game_draw_count += 1;
}

fn pluginAUpdate() void {
    plugin_a_update_count += 1;
}
fn pluginADraw() void {
    plugin_a_draw_count += 1;
}

fn pluginBUpdate() void {
    plugin_b_update_count += 1;
}
fn pluginBDraw() void {
    plugin_b_draw_count += 1;
}

fn childUpdate() void {
    child_update_count += 1;
}
fn childDraw() void {
    child_draw_count += 1;
}

// ------------------------------------------------------------
// Tests
// ------------------------------------------------------------

test "game update and draw call their own callbacks" {
    game_update_count = 0;
    game_draw_count = 0;

    var g = try game.Game.init(std.testing.allocator, gameUpdate, gameDraw);
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

    var g = try game.Game.init(std.testing.allocator, gameUpdate, gameDraw);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(std.testing.allocator, pluginAUpdate, pluginADraw));
    try g.addPlugin(try plugin.Plugin.init(std.testing.allocator, pluginBUpdate, pluginBDraw));

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

    var g = try game.Game.init(std.testing.allocator, gameUpdate, gameDraw);

    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(std.testing.allocator, pluginAUpdate, pluginADraw));

    // add a child plugin nested inside plugin A
    const pluginA = &g.plugin_handler.plugins.items[0];

    try pluginA.plugin_handler.addPlugin(
        try plugin.Plugin.init(std.testing.allocator, childUpdate, childDraw),
    );

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), game_update_count);
    try std.testing.expectEqual(@as(usize, 1), game_draw_count);

    try std.testing.expectEqual(@as(usize, 2), plugin_a_update_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_a_draw_count);

    // child must have been called the same number of times as its parent
    try std.testing.expectEqual(@as(usize, 2), child_update_count);
    try std.testing.expectEqual(@as(usize, 1), child_draw_count);
}
