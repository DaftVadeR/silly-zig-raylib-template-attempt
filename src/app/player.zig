const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const weapon = @import("weapon.zig");
const sprite = @import("sprite.zig");
const level = @import("level.zig");
const player_class = @import("player-class.zig");

pub const PlayerPlugin = struct {
    position: rl.Vector2,
    transform: rl.Vector2,
    player_detail: ?player_class.PlayerClass,
    level: ?*level.LevelPlugin, // optional as player needs to be loaded first

    pub fn draw(self: *PlayerPlugin) void {
        if (self.player_detail) |*pd| {
            pd.anims[pd.active_anim].draw(
                self.position,
                rl.Color.white,
                self.transform.x,
            );
        }
    }

    pub fn update(self: *PlayerPlugin) void {
        if (self.level) |lvl| {
            if (self.player_detail) |pd| {
                const player_w = pd.anims[pd.active_anim].frame_w;
                const player_h = pd.anims[pd.active_anim].frame_h;

                // clamp player position within level bounds, accounting for wall and sprite size
                self.position = rl.Vector2.clamp(
                    self.position,
                    lvl.bounds_min,
                    lvl.bounds.subtract(rl.Vector2{
                        .x = level.WALL_SIZE + player_w,
                        .y = level.WALL_SIZE + player_h,
                    }),
                );
            }
        }
    }

    pub fn onUnload(self: *PlayerPlugin, _: std.mem.Allocator) void {
        if (self.player_detail) |*pd| {
            pd.deinit();
        }
    }

    pub fn onLoad(self: *PlayerPlugin, alloc: std.mem.Allocator) void {
        self.player_detail = player_class.PlayerClass.init(alloc, player_class.PlayerKind.Knight) catch |err| {
            std.debug.print("Error loading player class: {}\n", .{err});
            unreachable;
        };

        self.level = &level.level;

        if (self.level) |lvl| {
            // center player in the level bounds on load
            self.position = rl.Vector2{
                .x = lvl.bounds.x / 2.0,
                .y = lvl.bounds.y / 2.0,
            };
        }

        // player_detail is now assigned and stable on the file-scoped player instance.
        // Patch the texture pointer in each anim to point at the owned texture field.
        if (self.player_detail) |*pd| {
            for (pd.anims) |*anim| {
                anim.texture = &pd.texture;
            }
        }
    }
};

pub var player = PlayerPlugin{
    .position = rl.Vector2{ .x = 0, .y = 5 },
    .transform = rl.Vector2{ .x = 1, .y = 0 }, // x: 1 = facing right, -1 = facing left
    .player_detail = null,
    .level = null, // optional to avoid double initializatoin dependency
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(PlayerPlugin, &player, alloc);
}
