const std = @import("std");
const plugin = @import("plugin.zig");
const plugin_handler = @import("plugin-handler.zig");

pub const Game = struct {
    allocator: std.mem.Allocator,
    plugin_handler: plugin_handler.PluginHandler,

    // TODO: add raylib arg to calls
    update: *const fn () void,
    draw: *const fn () void,

    pub fn init(
        alloc: std.mem.Allocator,
        rootOnUpdate: *const fn () void,
        rootOnDraw: *const fn () void,
    ) !Game {
        return Game{
            .allocator = alloc,
            .plugin_handler = try plugin_handler.PluginHandler.init(alloc),
            .update = rootOnUpdate,
            .draw = rootOnDraw,
        };
    }

    pub fn deinit(self: *Game) void {
        self.plugin_handler.deinit();
    }

    pub fn baseUpdate(self: *Game) void {
        // anything game-wide

        self.update();

        self.plugin_handler.update();
    }

    pub fn baseDraw(self: *Game) void {
        // anything game-wide

        self.draw();

        self.plugin_handler.draw();
    }
};

// pub fn getGame(allocator: std.mem.Allocator) Game{
//    return Game {
//        .allocator = allocator,
//        .plugins =
//    };
// }
