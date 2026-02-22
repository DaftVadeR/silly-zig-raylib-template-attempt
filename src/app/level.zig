const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const player = @import("player.zig");
const common = @import("common.zig");

// Handles movement input and animation state only — no player data ownership.
const LevelPlugin = struct {
    player: *player.PlayerPlugin,
    bounds: rl.Vector2,
    bounds_min: rl.Vector2,

    pub fn update(self: *LevelPlugin) void {
        // _ = self;
        std.debug.print("Level Plugin updating {}\n", .{self.player.position});
        self.player.position = rl.Vector2.clamp(self.player.position, self.bounds_min, self.bounds);
    }

    pub fn draw(self: *LevelPlugin) void {
        std.debug.print("Level Plugin drawing\n", .{});

        // draw surrounding wall
        rl.drawRectangle(
            @intFromFloat(self.bounds_min.x - 50),
            @intFromFloat(self.bounds_min.y - 50),
            @intFromFloat(self.bounds.x + 100),
            @intFromFloat(self.bounds.y + 100),
            rl.Color.dark_brown,
        );

        rl.drawRectangle(
            @intFromFloat(self.bounds_min.x),
            @intFromFloat(self.bounds_min.y),
            @intFromFloat(self.bounds.x),
            @intFromFloat(self.bounds.y),
            rl.Color.green,
        );
    }

    pub fn onLoad(self: *LevelPlugin, _: std.mem.Allocator) !void {
        std.debug.print("Level Plugin loaded\n", .{});

        // center player in the level bounds on load
        self.player.position = rl.Vector2{ .x = common.P1080.x / 2.0, .y = common.P1080.y / 2.0 };
    }
};

pub var level = LevelPlugin{
    .player = &player.player,
    .bounds_min = rl.Vector2{
        .x = 0,
        .y = 0,
    },
    .bounds = rl.Vector2{
        .x = 2000,
        .y = 2000,
    },
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(LevelPlugin, &level, alloc);
}
