const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");

pub const Plugin = struct {
    allocator: std.mem.Allocator,
    plugin_handler: plugin_handler.PluginHandler,
    update: *const fn () void,
    draw: *const fn () void,

    pub fn init(
        alloc: std.mem.Allocator,
        update: *const fn () void,
        draw: *const fn () void,
    ) !Plugin {
        return Plugin{
            .allocator = alloc,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
            .update = update,
            .draw = draw,
        };
    }

    pub fn deinit(self: *Plugin) void {
        self.plugin_handler.deinit();
    }

    pub fn baseUpdate(self: *Plugin) void {
        // anything else?
        self.update();
    }

    pub fn baseDraw(self: *Plugin) void {
        // anything else?
        self.draw();
    }
};
