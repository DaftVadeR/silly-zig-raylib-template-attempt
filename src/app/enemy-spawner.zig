const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const level = @import("level.zig");
const player = @import("player.zig");
const enemy_type = @import("enemy-type.zig");

const Enemy = struct {
    enemy_variant: enemy_type.EnemyVariant,
    position: rl.Vector2,
    rotation: f32,
    transform: rl.Vector2,

    pub fn init(self: Enemy, alloc: std.mem.Allocator) void {
        _ = self;
        _ = alloc;
    }

    pub fn deinit(self: Enemy, alloc: std.mem.Allocator) void {
        _ = self;
        _ = alloc;
    }

    pub fn update(self: *Enemy, alloc: std.mem.Allocator, frametime: f32) void {
        _ = frametime;
        _ = self;
        _ = alloc;
    }

    pub fn draw(self: *Enemy) void {
        _ = self;
    }
};

pub const EnemySpawnerPlugin = struct {
    level: ?*level.LevelPlugin, // optional as player needs to be loaded first
    player: ?*player.PlayerPlugin, // optional as player needs to be loaded first
    enemies: std.ArrayList(Enemy),
    wave: i32,
    time_since_last_spawn: f32,
    spawn_speed: f32,

    pub fn draw(self: *EnemySpawnerPlugin) void {
        for (self.enemies.items) |*enemy| {
            enemy.draw();
        }
    }

    pub fn update(self: *EnemySpawnerPlugin, alloc: std.mem.Allocator) void {
        const frameTime = rl.getFrameTime();

        for (self.enemies.items) |*enemy| {
            enemy.update(alloc, frameTime);
        }
    }

    pub fn onUnload(self: *EnemySpawnerPlugin, alloc: std.mem.Allocator) void {
        for (self.enemies.items) |*enemy| {
            enemy.deinit(alloc);
        }
    }

    pub fn onLoad(self: *EnemySpawnerPlugin, alloc: std.mem.Allocator) void {
        _ = alloc;
        self.player = &player.player;
        self.level = &level.level;
        self.spawn_speed = 1;
        self.time_since_last_spawn = 0;
        self.enemies = .empty;
    }
};

pub var enemy_spawner = EnemySpawnerPlugin{
    .player = null, // &player.player,
    .level = null, //&level.level, // optional to avoid double initializatoin dependency
    .time_since_last_spawn = 0,
    .spawn_speed = 1,
    .wave = 1,
    .enemies = .empty,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(EnemySpawnerPlugin, &enemy_spawner, alloc);
}
