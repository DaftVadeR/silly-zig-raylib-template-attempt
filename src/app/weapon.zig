const std = @import("std");
const rl = @import("raylib");
const p = @import("projectile.zig");

pub const Weapon = struct {
    name: []const u8,
    damage: i32,
    range: f32,
    damage_type: DamageType,
    impact_type: ImpactType,
    speed: f32,
    fire_speed: f32,
    time_since_fire: f32,
    projectiles: std.ArrayList(p.Projectile),
    position: rl.Vector2,
    rotation: f32,

    pub fn init(_: std.mem.Allocator, weaponType: WeaponType) void {
        if (weaponType == .EnergyWeapon) {
            return getEnergyWeapon();
        }
    }

    pub fn draw(self: *Weapon) void {
        for (self.projectiles.items) |*projectile| {
            projectile.draw();
        }
    }

    pub fn update(self: *Weapon, alloc: std.mem.Allocator, frametime: f32, position: rl.Vector2) void {
        self.position = position; // update weapon position to player position, so projectiles spawn from player

        self.time_since_fire += frametime;

        // std.debug.print("Updating weapon: {s}\n", .{self.name});

        // create new projectiles
        if (self.time_since_fire >= self.fire_speed) {
            const newProjectile = p.Projectile.init(
                self.position,
                self.rotation,
                self.speed,
            );

            self.projectiles.append(alloc, newProjectile) catch unreachable;

            self.time_since_fire = 0;
        }

        // update projectiles
        for (self.projectiles.items, 0..) |*projectile, i| {
            if (!projectile.enabled) {
                _ = self.projectiles.swapRemove(i);
            }

            projectile.update(frametime);
        }
    }

    pub fn deinit(self: *Weapon, _: std.mem.Allocator) void {
        self.projectiles.deinit();
    }
};

pub const WeaponType = enum {
    EnergyWeapon,
};

pub fn getEnergyWeapon(playerPosition: rl.Vector2, playerRotation: f32) Weapon {
    return Weapon{
        .name = "Energy Weapon",
        .damage = 10,
        .range = 10,
        .damage_type = .Lightning,
        .impact_type = .Direct,
        .speed = 0.5,
        .time_since_fire = 0,
        .projectiles = .empty,
        .position = playerPosition, // remember to update
        .rotation = playerRotation,
        .fire_speed = 0.5,
    };
}

// fn getEnergyWeapon() Weapon {
//     return Weapon{
//         .name = "Energy Weapon",
//         .damage = 10,
//         .range = 100,
//         .damage_type = .Fire,
//         .impact_type = .Direct,
//         .speed = 200,
//         .time_since_fire = 0,
//         .projectiles = std.ArrayList(Projectile).init(std.heap.page_allocator),
//     };
// }

pub const DamageType = enum {
    Physical,
    Fire,
    Ice,
    Lightning,
};

pub const ImpactType = enum {
    AOE,
    Direct,
};
