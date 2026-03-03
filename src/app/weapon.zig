const std = @import("std");

pub const Projectile = struct {
    enabled: bool, // used to turn off projectile, and used to identify which ones to delete on update

    pub fn init() void {}

    pub fn deinit() void {
        // not really anything?
    }

    pub fn update(self: Projectile, alloc: std.mem.Allocator, frametime: f32) void {
        _ = self;
        _ = alloc;
        _ = frametime;

        // do stuff with projectile movement for all projectiles
    }
};

pub const Weapon = struct {
    name: []const u8,
    damage: i32,
    range: f32,
    damage_type: DamageType,
    impact_type: ImpactType,
    speed: f32,
    time_since_fire: f32,
    projectiles: std.ArrayList(Projectile),

    pub fn init(_: std.mem.Allocator, weaponType: WeaponType) void {
        if (weaponType == .EnergyWeapon) {
            return getEnergyWeapon();
        }
    }

    pub fn update(self: Weapon, alloc: std.mem.Allocator, frametime: f32) void {
        for (self.projectiles.items) |*projectile| {
            projectile.update(alloc, frametime);
        }
    }

    pub fn deinit(self: Weapon, _: std.mem.Allocator) void {
        self.projectiles.deinit();
    }
};

pub const WeaponType = enum {
    EnergyWeapon,
};

pub fn getEnergyWeapon() Weapon {
    return Weapon{
        .name = "Energy Weapon",
        .damage = 10,
        .range = 100,
        .damage_type = .Lightning,
        .impact_type = .Direct,
        .speed = 200,
        .time_since_fire = 0,
        .projectiles = .empty,
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
