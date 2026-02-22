const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const player = @import("player.zig");

// Handles movement input and animation state only — no player data ownership.
const CameraPlugin = struct {
    player: *player.PlayerPlugin,

    pub fn update(self: *CameraPlugin) void {
        _ = self;
    }

    pub fn draw(_: *CameraPlugin) void {}

    pub fn onLoad(self: *CameraPlugin, _: std.mem.Allocator) !void {
        _ = self;

        // const camera2d: rl.Camera2D = .{
        //     .target = .{ 0, 0 },
        //     .offset = .{ 0, 0 },
        //     .rotation = 0,
        //     .zoom = 1,
        // };
        //
        // camera2d.target = self.player.playerPos; // Target the player
        // // Offset centers the camera on the screen
        // camera2d.offset = (rl.Vector2){ DESIRE / 2.0f, screenHeight / 2.0f };
        // camera2d.rotation = 0.0f;
        // camera2d.zoom = 1.0f;
    }
};

pub var camera = CameraPlugin{
    .player = &player.player,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(CameraPlugin, &camera, alloc);
}
