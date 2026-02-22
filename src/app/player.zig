const std = @import("std");
const rl = @import("raylib");
const game = @import("../lib/game.zig");
const plugin = @import("../lib/plugin.zig");

pub const PlayerPlugin = struct {
    position: rl.Vector2,
    transform: rl.Vector2,
    speed: u16,

    pub fn draw(self: PlayerPlugin) void {
        std.debug.print("drawing plyaer", .{self.speed});

        rl.drawTriangle(
            rl.Vector2{ .x = 0, .y = 0 },
            rl.Vector2{ .x = 100, .y = 100 },
            rl.Vector2{ .x = 200, .y = 200 },
            rl.Color.blue,
        );
    }

    pub fn update(self: *PlayerPlugin) void {
        std.debug.print("updating plyaer", .{self.speed});
        self.speed = 200;
    }
};

pub var player = PlayerPlugin{
    .position = rl.Vector2{ .x = 0, .y = 0 },
    .speed = 100,
    .transform = rl.Vector2{ .x = 0, .y = 0 },
};

pub fn addPlayerPlugin(alloc: std.mem.Allocator, g: *game.Game) void {
    g.plugin_handler.addPlugin(plugin.Plugin.init(
        alloc,
        player.update,
        player.draw,
    ));
}
