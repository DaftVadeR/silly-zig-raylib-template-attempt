const player = @import("player.zig");
const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");

// only handles movement behaviour, not data
const PlayerMovementPlugin = struct {
    player: *player.PlayerPlugin,

    pub fn draw(_: *PlayerMovementPlugin) void {
        std.debug.print("drawing movement (nothing)\n", .{});
    }

    pub fn update(self: *PlayerMovementPlugin) void {
        std.debug.print("Updating shape enemy...\n", .{});
        var inputDir = rl.Vector2.zero();

        const frameTime = rl.getFrameTime();

        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
            inputDir.y -= 1;
        }

        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
            inputDir.y += 1;
        }

        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
            inputDir.x -= 1;
        }

        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
            inputDir.x += 1;
        }

        // update facing direction based on horizontal input
        if (self.player.player_detail) |*pd| {
            if (inputDir.x < 0) {
                self.player.transform.x = -1;
            } else if (inputDir.y > 0) {
                self.player.transform.x = 1;
            }

            if (inputDir.x == 0 and inputDir.y == 0) {
                pd.active_anim = 1; // idle
            } else {
                pd.active_anim = 0; // run
            }

            // normalize so diagonal movement isnt faster than cardinal
            const normalized = rl.Vector2.normalize(inputDir);
            // const movement = vec2.mulN(normalized, speed * frameTime);

            self.player.position.x += pd.attributes.speed * frameTime * normalized.x;
            self.player.position.y += pd.attributes.speed * frameTime * normalized.y;

            // if (pd.anims) |anims| {
            pd.anims[pd.active_anim].update(frameTime);
            // }
        }

        // if no horizontal input, keep the last facing direction

        // const newVec = rl.Vector2{
        //     .x = target.player_detail.attributes.position.x - attribs.position.x,
        //     .y = target.player_detail.attributes.position.y - attribs.position.y,
        // };
        //
        // const norm = newVec.normalize();
        //
        // const diff = rl.Vector2{
        //     .x = norm.x * attribs.speed * frameTime,
        //     .y = norm.y * attribs.speed * frameTime,
        // };
        //
        // attribs.position.x += diff.x;
        // attribs.position.x += diff.y;
    }

    // pub fn update(self: *PlayerMovementPlugin) void {
    //     var inputDir: vec2.V = vec2.ZERO;
    //
    //     const frameTime = rl.getFrameTime();
    //     const speed = self.player_detail.attributes.speed;
    //
    //     // collect raw direction input (-1/+1 per axis)
    //     if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
    //         inputDir[1] -= 1;
    //     }
    //
    //     if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
    //         inputDir[1] += 1;
    //     }
    //
    //     if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
    //         inputDir[0] -= 1;
    //     }
    //
    //     if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
    //         inputDir[0] += 1;
    //     }
    //
    //     // update facing direction based on horizontal input
    //     if (inputDir[0] < 0) {
    //         self.player_detail.attributes.transform.x = -1;
    //     } else if (inputDir[0] > 0) {
    //         self.player_detail.attributes.transform.x = 1;
    //     }
    //     // if no horizontal input, keep the last facing direction
    //
    //     if (inputDir[0] == 0 and inputDir[1] == 0) {
    //         self.player_detail.attributes.default_anim = 0; // idle
    //     } else {
    //         self.player_detail.attributes.default_anim = 1; // run
    //     }
    //
    //     // normalize so diagonal movement isnt faster than cardinal
    //     const normalized = vec2.normalize(inputDir);
    //     const movement = vec2.mulN(normalized, speed * frameTime);
    //
    //     self.player_detail.attributes.position.x += movement[0];
    //     self.player_detail.attributes.position.y += movement[1];
    //
    //     if (self.player_detail.attributes.anims) |anims| {
    //         anims[self.player_detail.attributes.default_anim].update(frameTime);
    //     }
    // }

    // pub fn update(self: *PlayerMovementPlugin) void {
    //
    //     // self.speed = 200;
    //     // self.position.x += @floatFromInt(self.speed);
    // }

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
