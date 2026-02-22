const player = @import("player.zig");
const std = @import("std");
const plugin = @import("../lib/plugin.zig");

// only handles movement behaviour, not data
const PlayerMovementPlugin = struct {
    player: *player.PlayerPlugin,

    pub fn draw(_: *PlayerMovementPlugin) void {
        std.debug.print("drawing movement (nothing)\n", .{});
    }

    pub fn update(self: *PlayerMovementPlugin) void {
        std.debug.print("updating player movement {}\n", .{self.player.position});

        // self.speed = 200;
        // self.position.x += @floatFromInt(self.speed);
    }

    pub fn onLoad(_: *PlayerMovementPlugin, _: std.mem.Allocator) !void {
        std.debug.print("player movement loaded\n", .{});
    }
};

pub var movement = PlayerMovementPlugin{
    .player = &player.player,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(
        PlayerMovementPlugin,
        &movement,
        alloc,
    );
}
