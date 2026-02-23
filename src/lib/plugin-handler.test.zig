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
var plugin_a_load_count: usize = 0;
var plugin_a_unload_count: usize = 0;
var plugin_b_update_count: usize = 0;
var plugin_b_draw_count: usize = 0;
var plugin_b_load_count: usize = 0;
var plugin_b_unload_count: usize = 0;
var child_update_count: usize = 0;
var child_draw_count: usize = 0;
var child_load_count: usize = 0;
var child_unload_count: usize = 0;

// -- Ordering helpers --
var call_order: [16]u8 = undefined;
var call_order_len: usize = 0;

fn resetCallOrder() void {
    call_order_len = 0;
}

fn recordCall(id: u8) void {
    if (call_order_len < call_order.len) {
        call_order[call_order_len] = id;
        call_order_len += 1;
    }
}

fn getCallOrder() []const u8 {
    return call_order[0..call_order_len];
}

fn resetAllCounters() void {
    game_update_count = 0;
    game_draw_count = 0;
    plugin_a_update_count = 0;
    plugin_a_draw_count = 0;
    plugin_a_load_count = 0;
    plugin_a_unload_count = 0;
    plugin_b_update_count = 0;
    plugin_b_draw_count = 0;
    plugin_b_load_count = 0;
    plugin_b_unload_count = 0;
    child_update_count = 0;
    child_draw_count = 0;
    child_load_count = 0;
    child_unload_count = 0;
    resetCallOrder();
}

// ------------------------------------------------------------
// Stub structs — one per counter pair, each with update/draw/onLoad/onUnload
// ------------------------------------------------------------

const GameRoot = struct {
    pub fn update(_: *GameRoot) void {
        game_update_count += 1;
    }
    pub fn draw(_: *GameRoot) void {
        game_draw_count += 1;
    }
    pub fn onLoad(_: *GameRoot, _: std.mem.Allocator) void {}
    pub fn onUnload(_: *GameRoot, _: std.mem.Allocator) void {}
};

const PluginA = struct {
    pub fn update(_: *PluginA) void {
        plugin_a_update_count += 1;
        recordCall('A');
    }
    pub fn draw(_: *PluginA) void {
        plugin_a_draw_count += 1;
        recordCall('A');
    }
    pub fn onLoad(_: *PluginA, _: std.mem.Allocator) void {
        plugin_a_load_count += 1;
    }
    pub fn onUnload(_: *PluginA, _: std.mem.Allocator) void {
        plugin_a_unload_count += 1;
    }
};

const PluginB = struct {
    pub fn update(_: *PluginB) void {
        plugin_b_update_count += 1;
        recordCall('B');
    }
    pub fn draw(_: *PluginB) void {
        plugin_b_draw_count += 1;
        recordCall('B');
    }
    pub fn onLoad(_: *PluginB, _: std.mem.Allocator) void {
        plugin_b_load_count += 1;
    }
    pub fn onUnload(_: *PluginB, _: std.mem.Allocator) void {
        plugin_b_unload_count += 1;
    }
};

const ChildPlugin = struct {
    pub fn update(_: *ChildPlugin) void {
        child_update_count += 1;
        recordCall('C');
    }
    pub fn draw(_: *ChildPlugin) void {
        child_draw_count += 1;
        recordCall('C');
    }
    pub fn onLoad(_: *ChildPlugin, _: std.mem.Allocator) void {
        child_load_count += 1;
    }
    pub fn onUnload(_: *ChildPlugin, _: std.mem.Allocator) void {
        child_unload_count += 1;
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
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), game_update_count);
    try std.testing.expectEqual(@as(usize, 1), game_draw_count);
}

test "game update and draw propagate to plugins" {
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));
    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginB, &plugin_b, std.testing.allocator));

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
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));

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

test "onLoad fires exactly once per plugin at addPlugin time" {
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));
    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginB, &plugin_b, std.testing.allocator));

    // onLoad should have fired once for each plugin during addPlugin
    try std.testing.expectEqual(@as(usize, 1), plugin_a_load_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_b_load_count);

    // subsequent updates should not trigger onLoad again
    g.update();
    g.update();

    try std.testing.expectEqual(@as(usize, 1), plugin_a_load_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_b_load_count);
}

test "plugins update and draw in addPlugin registration order" {
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));
    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginB, &plugin_b, std.testing.allocator));

    // update: game root runs first (no recordCall), then A, then B
    g.update();
    try std.testing.expectEqualSlices(u8, "AB", getCallOrder());

    // draw order should also be A then B
    resetCallOrder();
    g.draw();
    try std.testing.expectEqualSlices(u8, "AB", getCallOrder());
}

test "deinit calls onUnload on all plugins" {
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));
    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginB, &plugin_b, std.testing.allocator));

    try std.testing.expectEqual(@as(usize, 0), plugin_a_unload_count);
    try std.testing.expectEqual(@as(usize, 0), plugin_b_unload_count);

    g.deinit();

    try std.testing.expectEqual(@as(usize, 1), plugin_a_unload_count);
    try std.testing.expectEqual(@as(usize, 1), plugin_b_unload_count);
}

test "nested plugin onUnload propagates on deinit" {
    resetAllCounters();

    var g = try game.Game.init(GameRoot, &game_root, std.testing.allocator);

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(PluginA, &plugin_a, std.testing.allocator));

    const first = &g.plugin_handler.plugins.items[0];
    try first.plugin_handler.addPlugin(
        try plugin.Plugin.init(ChildPlugin, &child_plugin, std.testing.allocator),
    );

    try std.testing.expectEqual(@as(usize, 0), plugin_a_unload_count);
    try std.testing.expectEqual(@as(usize, 0), child_unload_count);

    g.deinit();

    try std.testing.expectEqual(@as(usize, 1), plugin_a_unload_count);
    try std.testing.expectEqual(@as(usize, 1), child_unload_count);
}
