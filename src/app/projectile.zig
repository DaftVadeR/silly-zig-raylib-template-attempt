pub const Projectile = struct {
    name: []const u8,
    damage: i32,
    range: f32,
    damage_type: DamageType,
    impact_type: ImpactType,
    speed: f32,
    time_since_fire: f32,

    fn fire() void {}
};
