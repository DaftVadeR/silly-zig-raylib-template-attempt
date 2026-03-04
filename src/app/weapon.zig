const std = @import("std");
const rl = @import("raylib");
const p = @import("projectile.zig");

pub const Weapon = struct {
    name: []const u8,
    damage: i32,
    range: f32,
    weapon_type: WeaponType,
    projectile_type: p.ProjectileType,
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

    pub fn update(self: *Weapon, alloc: std.mem.Allocator, frametime: f32, position: rl.Vector2, rotation: f32) void {
        self.position = position; // update weapon position to player position, so projectiles spawn from player
        self.rotation = rotation;

        self.time_since_fire += frametime;

        // std.debug.print("Updating weapon: {s}\n", .{self.name});

        // create new projectiles
        if (self.time_since_fire >= self.fire_speed) {
            const newProjectile = p.Projectile.init(
                self.position,
                self.rotation,
                self.speed,
                self.projectile_type,
            );

            self.projectiles.append(alloc, newProjectile) catch unreachable;

            self.time_since_fire = 0;
        }

        // update projectiles
        for (self.projectiles.items, 0..) |*projectile, i| {
            const distance = self.position.subtract(projectile.position); // update weapon position to player position, so projectiles spawn from player
            //
            // const distanceX = projectile.position.x - self.position.x; // simple distance calculation, can be improved with actual distance formula
            // const distance = projectile.position.x - self.position.x; // simple distance calculation, can be improved with actual distance formula

            // compare distance to range on weapon. if exceeded, set projectil to disabled.
            //
            //if(weapon.range <= projectile.)
            // {}
            _ = distance; // just to avoid unused variable warning for now

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
    IceBlockWeapon,
    FireballWeapon,
};

pub fn getEnergyWeapon(playerPosition: rl.Vector2, playerRotation: f32) Weapon {
    return Weapon{
        .name = "Energy Weapon",
        .damage = 10,
        .range = 15,
        .weapon_type = .EnergyWeapon,
        .projectile_type = .EnergyProjectile,
        .time_since_fire = 0,
        .speed = 0.7,
        .projectiles = .empty,
        .position = playerPosition, // remember to update
        .rotation = playerRotation,
        .fire_speed = 0.7,
    };
}

pub fn getFireballWeapon(playerPosition: rl.Vector2, playerRotation: f32) Weapon {
    return Weapon{
        .name = "Fireball Weapon",
        .damage = 20,
        .range = 10,
        .weapon_type = .FireballWeapon,
        .projectile_type = .FireBall,
        .speed = 0.4,
        .time_since_fire = 0,
        .projectiles = .empty,
        .position = playerPosition, // remember to update
        .rotation = playerRotation,
        .fire_speed = 0.5,
    };
}

pub fn getIceBlockWeapon(playerPosition: rl.Vector2, playerRotation: f32) Weapon {
    return Weapon{
        .name = "Ice block Weapon",
        .damage = 40,
        .range = 10,
        .weapon_type = .IceBlockWeapon,
        .projectile_type = .IceBlock,
        .speed = 0.4,
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
