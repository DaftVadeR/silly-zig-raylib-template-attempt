const std = @import("std");
const sprite = @import("sprite.zig");
const weapon = @import("weapon.zig");
const player = @import("player.zig");
const rl = @import("raylib");

pub const EnemyType = enum {
    Goblin,
};

const EnemyAttributes = struct {
    damage: f32,
};

pub const EnemyVariant = struct {
    texture: rl.Texture2D,
    attributes: EnemyAttributes,
    anims: []sprite.SpriteAnim,
    active_anim: usize,
    enemy_type: EnemyType,
    weapon: ?weapon.Weapon,

    pub fn init(alloc: std.mem.Allocator, enemyType: EnemyType) !EnemyVariant {
        return switch (enemyType) {
            .Goblin => getGoblin(alloc),
        };
    }

    pub fn deinit(self: *EnemyVariant, alloc: std.mem.Allocator) void {
        rl.unloadTexture(self.texture);

        alloc.free(self.anims);
        self.weapons.deinit(alloc);
    }

    pub fn update(
        self: *EnemyVariant,
        alloc: std.mem.Allocator,
        frametime: f32,
        position: rl.Vector2,
        rotation: f32,
    ) void {
        for (self.weapons.items) |*wpn| {
            wpn.update(alloc, frametime, position, rotation);
        }
    }

    pub fn draw(self: *EnemyVariant) void {
        for (self.weapons.items) |*wpn| {
            wpn.draw();
        }
    }
};

pub fn getGoblin(alloc: std.mem.Allocator) !EnemyVariant {
    var anims = try alloc.alloc(sprite.SpriteAnim, 1);

    // var weapons: std.ArrayList(weapon.Weapon) = .empty;
    // try weapons.append(alloc, weapon.getEnergyWeapon(
    //     player.player.position,
    //     player.player.rotation,
    // ));

    const texture = try rl.Texture.init(
        "resources/images/enemy/goblin/goblin_spritesheet.png",
    );

    rl.setTextureFilter(texture, rl.TextureFilter.point);

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
        0,
        6,
        10,
    );

    return EnemyVariant{
        .texture = texture,
        .attributes = .{
            .damage = 10,
        },
        .anims = anims,
        .weapon = null,
        .enemy_type = .Goblin,
        .active_anim = 0,
    };
}
