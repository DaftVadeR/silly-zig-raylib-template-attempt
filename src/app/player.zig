const std = @import("std");
const rl = @import("raylib");
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
};

pub const PlayerClass = struct {
    allocator: std.mem.Allocator,
    texture: rl.Texture2D,
    attributes: CharacterAttributes,
    weapons: []weapon.Weapon,
    anims: []sprite.SpriteAnim,
    active_anim: usize,
    player_type: PlayerKind,

    pub fn init(alloc: std.mem.Allocator, playerKind: PlayerKind) !PlayerClass {
        return switch (playerKind) {
            .Karen, .Knight => getKnight(alloc, playerKind),
        };
    }

    pub fn deinit(self: *PlayerClass) void {
        rl.unloadTexture(self.texture);

        self.allocator.free(self.anims);
        self.allocator.free(self.weapons);
    }
};

pub fn getKnight(alloc: std.mem.Allocator, kind: PlayerKind) !PlayerClass {
    var anims = try alloc.alloc(sprite.SpriteAnim, 2);
    var weapons = try alloc.alloc(weapon.Weapon, 1);

    weapons[0] = weapon.energyWeapon;

    // Build PlayerClass first so texture has a stable address.
    // Anims are initialised with a placeholder — fixupAnims patches the pointer below.
    const texture = try rl.Texture.init("resources/images/player/knight_spritesheet.png");

    // anims[0] = idle (frames 0–5), anims[1] = run (frames 6–11).
    // We pass &player.player_detail's texture after onLoad sets it.
    // Since player_detail is ?PlayerClass on the file-scoped player instance,
    // we store a temporary dummy texture reference here and fix it up in onLoad
    // once player_detail has a stable address.
    anims[0] = sprite.SpriteAnim.init(&texture, 16, 16, 6, 0, 6, 10);
    anims[1] = sprite.SpriteAnim.init(&texture, 16, 16, 6, 6, 6, 10);

    return PlayerClass{
        .allocator = alloc,
        .texture = texture,
        .attributes = .{
            .speed = 300,
            .magic = 50,
            .strength = 50,
            .attack_speed = 50,
        },
        .anims = anims,
        .weapons = weapons,
        .player_type = kind,
        .active_anim = 0,
    };
}

pub const PlayerPlugin = struct {
    position: rl.Vector2,
    transform: rl.Vector2,
    player_detail: ?PlayerClass,

    pub fn draw(self: *PlayerPlugin) void {
        if (self.player_detail) |*pd| {
            pd.anims[pd.active_anim].draw(self.position, 5.0, rl.Color.white, self.transform.x);
        }
    }

    pub fn update(_: *PlayerPlugin) void {}

    pub fn onLoad(self: *PlayerPlugin, alloc: std.mem.Allocator) !void {
        self.player_detail = try PlayerClass.init(alloc, PlayerKind.Knight);
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
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(PlayerPlugin, &player, alloc);
}
