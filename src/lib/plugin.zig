const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");

pub const Plugin = struct {
    ctx: *anyopaque,
    update_fn: *const fn (*anyopaque) void,
    draw_fn: *const fn (*anyopaque) void,
    plugin_handler: plugin_handler.PluginHandler,

    /// Pass any struct type T and a pointer to an instance of it.
    /// T must have `update` and `draw` methods that take `*T`.
    /// The plugin does NOT own the instance — the caller must keep it alive.
    pub fn init(comptime T: type, instance: *T, alloc: std.mem.Allocator) !Plugin {
        const gen = struct {
            fn update(ctx: *anyopaque) void {
                const self: *T = @ptrCast(@alignCast(ctx));
                self.update();
            }
            fn draw(ctx: *anyopaque) void {
                const self: *T = @ptrCast(@alignCast(ctx));
                self.draw();
            }
        };

        return Plugin{
            .ctx = instance,
            .update_fn = gen.update,
            .draw_fn = gen.draw,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
        };
    }

    pub fn deinit(self: *Plugin) void {
        self.plugin_handler.deinit();
    }

    pub fn update(self: *Plugin) void {
        self.update_fn(self.ctx);
        self.plugin_handler.update();
    }

    pub fn draw(self: *Plugin) void {
        self.draw_fn(self.ctx);
        self.plugin_handler.draw();
    }
};
