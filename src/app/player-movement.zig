const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const player = @import("player.zig");

// Handles movement input and animation state only — no player data ownership.
pub const PlayerMovementPlugin = struct {
    player: *player.PlayerPlugin,

    pub fn update(self: *PlayerMovementPlugin) void {
        var inputDir = rl.Vector2.zero();
        const frameTime = rl.getFrameTime();

        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) inputDir.y -= 1;
        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) inputDir.y += 1;
        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) inputDir.x -= 1;
        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) inputDir.x += 1;

        if (self.player.player_detail) |*pd| {
            // Always tick the active anim regardless of input.
            pd.anims[pd.active_anim].update(frameTime);

            // Switch animation based on whether the player is moving.
            if (inputDir.x == 0 and inputDir.y == 0) {
                pd.active_anim = 0; // idle
            } else {
                pd.active_anim = 1; // run
            }

            // Update facing direction based on horizontal input.
            if (inputDir.x < 0) {
                self.player.transform.x = -1;
            } else if (inputDir.x > 0) {
                self.player.transform.x = 1;
            }

            // Normalize so diagonal movement is not faster than cardinal.
            const normalized = rl.Vector2.normalize(inputDir);
            self.player.position.x += pd.attributes.speed * frameTime * normalized.x;
            self.player.position.y += pd.attributes.speed * frameTime * normalized.y;
        }
    }

    pub fn draw(_: *PlayerMovementPlugin) void {}

    pub fn onLoad(_: *PlayerMovementPlugin, _: std.mem.Allocator) void {}

    pub fn onUnload(_: *PlayerMovementPlugin, _: std.mem.Allocator) void {
        // if (self.player_detail) |*pd| {
        //     pd.deinit();
        // }
    }
};

pub var movement = PlayerMovementPlugin{
    .player = &player.player,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(PlayerMovementPlugin, &movement, alloc);
}
