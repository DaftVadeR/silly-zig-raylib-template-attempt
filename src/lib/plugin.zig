const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");

pub const Plugin = struct {
    ctx: *anyopaque,
    update_fn: *const fn (*anyopaque) void,
    draw_fn: *const fn (*anyopaque) void,
    load_fn: *const fn (*anyopaque, std.mem.Allocator) anyerror!void,
    plugin_handler: plugin_handler.PluginHandler,

    /// T must have `update`, `draw`, and `onLoad` methods.
    /// `update` and `draw` take `*T`.
    /// `onLoad` takes `*T` and `std.mem.Allocator` and returns `anyerror!void`.
    /// The caller must keep the instance alive for the lifetime of the plugin.
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
            fn load(ctx: *anyopaque, a: std.mem.Allocator) anyerror!void {
                const self: *T = @ptrCast(@alignCast(ctx));
                try self.onLoad(a);
            }
        };

        return Plugin{
            .ctx = instance,
            .update_fn = gen.update,
            .draw_fn = gen.draw,
            .load_fn = gen.load,
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

    pub fn load(self: *Plugin, alloc: std.mem.Allocator) !void {
        try self.load_fn(self.ctx, alloc);
    }
};
