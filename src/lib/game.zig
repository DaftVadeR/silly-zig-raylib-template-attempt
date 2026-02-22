const std = @import("std");
const plugin_handler = @import("plugin-handler.zig");
const plugin = @import("plugin.zig");

pub const Game = struct {
    allocator: std.mem.Allocator,
    plugin_handler: plugin_handler.PluginHandler,
    ctx: *anyopaque,
    update_fn: *const fn (*anyopaque) void,
    draw_fn: *const fn (*anyopaque) void,

    pub fn init(comptime T: type, instance: *T, alloc: std.mem.Allocator) !Game {
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

        return Game{
            .allocator = alloc,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
            .ctx = instance,
            .update_fn = gen.update,
            .draw_fn = gen.draw,
        };
    }

    pub fn deinit(self: *Game) void {
        self.plugin_handler.deinit();
    }

    pub fn update(self: *Game) void {
        self.update_fn(self.ctx);
        self.plugin_handler.update();
    }

    pub fn draw(self: *Game) void {
        self.draw_fn(self.ctx);
        self.plugin_handler.draw();
    }
};
