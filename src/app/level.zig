const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const player = @import("player.zig");
const common = @import("common.zig");

const Tilemap = struct {
    texture: rl.Texture2D,
};

pub const WALL_SIZE: f32 = 50;

// Just draw random tiles from tilemaps for now.
pub const LevelPlugin = struct {
    tilemaps: ?[]Tilemap, // tilemaps to draw from, in order of addition to slice
    // player: *player.PlayerPlugin,
    bounds: rl.Vector2,
    bounds_min: rl.Vector2,

    pub fn update(self: *LevelPlugin) void {
        _ = self;

        std.debug.print("Level Plugin updating\n", .{});
    }

    pub fn draw(self: *LevelPlugin) void {
        std.debug.print("Level Plugin drawing\n", .{});

        // draw surrounding wall
        rl.drawRectangle(
            @intFromFloat(self.bounds_min.x - WALL_SIZE),
            @intFromFloat(self.bounds_min.y - WALL_SIZE),
            @intFromFloat(self.bounds.x + WALL_SIZE * 2),
            @intFromFloat(self.bounds.y + WALL_SIZE * 2),
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

    pub fn onUnload(self: *LevelPlugin, alloc: std.mem.Allocator) void {
        if (self.tilemaps) |tilemaps| {
            for (tilemaps) |tilemap| {
                rl.unloadTexture(tilemap.texture);
            }
        }

        if (self.tilemaps) |tilemaps| {
            alloc.free(tilemaps);
        }
    }

    pub fn onLoad(self: *LevelPlugin, alloc: std.mem.Allocator) void {
        std.debug.print("Level Plugin loaded\n", .{});

        self.tilemaps = alloc.alloc(Tilemap, 1) catch |err| {
            std.debug.print("Error allocating tilemaps: {}\n", .{err});
            unreachable;
        };

        const texture = rl.loadTexture("resources/images/level/tx_tileset_grass.png") catch |err| {
            std.debug.print("Error loading tilemap texture: {}\n", .{err});
            unreachable;
        };

        if (self.tilemaps) |*tilemaps| {
            tilemaps.*[0] = Tilemap{
                .texture = texture,
            };
        }
    }
};

pub var level = LevelPlugin{
    .bounds_min = rl.Vector2{
        .x = 0,
        .y = 0,
    },
    .bounds = rl.Vector2{
        .x = 2000,
        .y = 2000,
    },
    .tilemaps = null,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(LevelPlugin, &level, alloc);
}
