const std = @import("std");
const sprite = @import("sprite.zig");
const weapon = @import("weapon.zig");
const rl = @import("raylib");

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
    anims[0] = sprite.SpriteAnim.init(
        &texture,
        16,
        16,
        6,
        0,
        6,
        10,
    );
    anims[1] = sprite.SpriteAnim.init(
        &texture,
        16,
        16,
        6,
        6,
        6,
        10,
    );

    return PlayerClass{
        .allocator = alloc,
        .texture = texture,
        .attributes = .{
            .speed = 60,
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
