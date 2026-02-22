const std = @import("std");
const rl = @import("raylib");
const game = @import("../lib/game.zig");
const plugin = @import("../lib/plugin.zig");

pub const PlayerPlugin = struct {
    position: rl.Vector2,
    transform: rl.Vector2,
    speed: u16,

    pub fn draw(self: *PlayerPlugin) void {
        _ = self;
        rl.drawTriangle(
            rl.Vector2{ .x = 0, .y = 0 },
            rl.Vector2{ .x = 100, .y = 100 },
            rl.Vector2{ .x = 200, .y = 200 },
            rl.Color.blue,
        );
    }

    pub fn update(self: *PlayerPlugin) void {
        self.speed = 200;
        self.position.x += @floatFromInt(self.speed);
    }
};

pub var player = PlayerPlugin{
    .position = rl.Vector2{ .x = 0, .y = 0 },
    .speed = 100,
    .transform = rl.Vector2{ .x = 0, .y = 0 },
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(PlayerPlugin, &player, alloc);
}
