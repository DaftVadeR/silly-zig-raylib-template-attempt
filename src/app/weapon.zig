const std = @import("std");

pub const Weapon = struct {
    name: []const u8,
    damage: i32,
    range: f32,
    damage_type: DamageType,
    impact_type: ImpactType,
};

pub const energyWeapon = Weapon{
    .name = "Energy Weapon",
    .damage = 10,
    .range = 100.0,
    .damage_type = .Physical,
    .impact_type = .Direct,
};

pub const DamageType = enum {
    Physical,
};

pub const ImpactType = enum {
    AOE,
    Direct,
};
