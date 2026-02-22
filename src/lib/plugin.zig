const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");

pub const Plugin = struct {
    update_fn: *const fn () void,
    draw_fn: *const fn () void,
    plugin_handler: plugin_handler.PluginHandler,

    pub fn init(
        alloc: std.mem.Allocator,
        update_fn: *const fn () void,
        draw_fn: *const fn () void,
    ) !Plugin {
        return Plugin{
            .update_fn = update_fn,
            .draw_fn = draw_fn,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
        };
    }

    pub fn deinit(self: *Plugin) void {
        self.plugin_handler.deinit();
    }

    pub fn update(self: *Plugin) void {
        self.update_fn();
        self.plugin_handler.update();
    }

    pub fn draw(self: *Plugin) void {
        self.draw_fn();
        self.plugin_handler.draw();
    }
};
