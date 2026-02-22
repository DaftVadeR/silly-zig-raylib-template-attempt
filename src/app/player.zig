const std = @import("std");
const rl = @import("raylib");
const game = @import("../lib/game.zig");
const plugin = @import("../lib/plugin.zig");

const weapon = @import("weapon.zig");
const sprite = @import("sprite.zig");

pub const PlayerKind = enum {
    Karen,
    Knight,
};

const CharacterAttributes = struct {
    strength: f32,
    magic: f32,
    speed: f32,
    attack_speed: f32,

    // fn deinit(alloc: std.mem.Allocator) void {
    //
    // }
};

pub const PlayerClass = struct {
    attributes: CharacterAttributes,
    weapons: []weapon.Weapon,
    anims: []sprite.SpriteAnim,
    player_type: PlayerKind,

    pub fn init(
        alloc: std.mem.Allocator,
        playerKind: PlayerKind,
    ) !PlayerClass {
        return switch (playerKind) {
            .Karen => getKnight(alloc, playerKind),
            .Knight => getKnight(alloc, playerKind),
        };

        // return PlayerClass{
        //     .attributes = attributes,
        //     .default_weapons = defWeapons,
        //     .anims = anims,
        // };
    }

    pub fn deinit(self: *PlayerClass) void {
        std.debug.print("Deinitializing CharacterAttributes...\n", .{});

        // self.attributes.deinit();

        for (self.anims) |*anim| {
            anim.denit();
        }

        self.allocator.free(self.anims);
        self.allocator.free(self.default_weapons);
    }
};

pub fn getKnight(allocator: std.mem.Allocator, kind: PlayerKind) !PlayerClass {
    var anims = try allocator.alloc(sprite.SpriteAnim, 2);

    var weapons = try allocator.alloc(weapon.Weapon, 1);

    const texture = try rl.Texture.init(
        "resources/images/player/knight_spritesheet.png",
    );

    anims[0] = try sprite.SpriteAnim.init(
        texture,
        16,
        16,
        6,
        12,
        10,
    );

    anims[1] = try sprite.SpriteAnim.init(
        texture,
        16,
        16,
        6,
        12,
        10,
    );

    weapons[0] = weapon.energyWeapon;

    return PlayerClass{
        .attributes = .{
            .speed = 50,
            .magic = 50,
            .strength = 50,
            .attack_speed = 50,
        },
        .anims = anims,
        .weapons = weapons,
        .player_type = kind,
    };
}

pub const PlayerPlugin = struct {
    position: rl.Vector2,
    transform: rl.Vector2,
    player_detail: ?PlayerClass,

    // last_run: usize,
    // run_level: usize,
    // experience: f128,
    // level: i32,

    pub fn draw(self: *PlayerPlugin) void {
        std.debug.print("drawing player\n", .{});

        if (self.player_detail) |pd| {
            pd.anims[0].draw(
                self.position,
                5.0,
                rl.Color.white,
            );
        }

        // rl.drawTriangle(
        //     rl.Vector2{ .x = 0, .y = 0 },
        //     rl.Vector2{ .x = 100, .y = 100 },
        //     rl.Vector2{ .x = 200, .y = 200 },
        //     rl.Color.blue,
        // );
        //
        // rl.drawRectangle(
        //     @as(i32, 0),
        //     @as(i32, 0),
        //     @as(i32, 300),
        //     @as(i32, 300),
        //     rl.Color.blue,
        // );
    }

    pub fn update(_: *PlayerPlugin) void {
        std.debug.print("updating player\n", .{});

        // self.speed = 200;
        // self.position.x += @floatFromInt(self.speed);
    }

    pub fn onLoad(self: *PlayerPlugin, alloc: std.mem.Allocator) !void {
        std.debug.print("player loaded\n", .{});

        self.player_detail = try PlayerClass.init(alloc, PlayerKind.Knight);
    }
};

pub var player = PlayerPlugin{
    .position = rl.Vector2{ .x = 0, .y = 0 },
    .transform = rl.Vector2{ .x = 0, .y = 0 },
    .player_detail = null,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(
        PlayerPlugin,
        &player,
        alloc,
    );
}
