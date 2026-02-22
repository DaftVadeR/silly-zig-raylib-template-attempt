const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");
const plugin = @import("plugin.zig");

pub const Game = struct {
    allocator: std.mem.Allocator,
    plugin_handler: plugin_handler.PluginHandler,
    update_fn: *const fn () void,
    draw_fn: *const fn () void,

    pub fn init(
        alloc: std.mem.Allocator,
        update_fn: *const fn () void,
        draw_fn: *const fn () void,
    ) !Game {
        return Game{
            .allocator = alloc,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
            .update_fn = update_fn,
            .draw_fn = draw_fn,
        };
    }

    pub fn deinit(self: *Game) void {
        self.plugin_handler.deinit();
    }

    pub fn addPlugin(self: *Game, p: plugin.Plugin) !void {
        try self.plugin_handler.addPlugin(p);
    }

    pub fn update(self: *Game) void {
        self.update_fn();
        self.plugin_handler.update();
    }

    pub fn draw(self: *Game) void {
        self.draw_fn();
        self.plugin_handler.draw();
    }
};
