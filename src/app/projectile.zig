const std = @import("std");
const weapon = @import("weapon.zig");
const rl = @import("raylib");

pub const ProjectileType = enum {
    EnergyProjectile,
};

pub const Projectile = struct {
    type: ProjectileType,
    enabled: bool, // used to turn off projectile, and used to identify which ones to delete on update
    position: rl.Vector2,
    rotation: f32,
    speed: f32,

    pub fn init(origin: rl.Vector2, rotation: f32, speed: f32) Projectile {
        return Projectile{
            .enabled = true,
            .type = .EnergyProjectile,
            .position = origin,
            .rotation = rotation,
            .speed = speed,
        };
    }

    pub fn deinit() void {
        // not really anything?
    }

    pub fn update(self: *Projectile, frametime: f32) void {
        const length = 5;

        const end_x = self.position.x + length * std.math.cos(self.rotation) * self.speed;
        const end_y = self.position.y + length * std.math.sin(self.rotation) * self.speed;

        const endPos = rl.Vector2{ .x = end_x, .y = end_y };
        // _ = frametime; // just to avoid unused variable warning for now;
        // _ = endPos; // just to avoid unused variable warning for now

        self.position = rl.Vector2{
            .x = endPos.x + frametime * self.speed,
            .y = endPos.y + frametime * self.speed,
        };

        // do stuff with projectile movement for all projectiles
    }

    pub fn draw(self: *Projectile) void {
        // std.debug.print("Drawing projectile at position: ({}, {})\n", .{ self.position.x, self.position.y });
        // draw the projectile based on type
        switch (self.type) {
            .EnergyProjectile => {
                rl.drawLineEx(
                    self.position,
                    rl.Vector2{
                        .x = self.position.x + 10 * std.math.cos(self.rotation),
                        .y = self.position.y + 10 * std.math.sin(self.rotation),
                    },
                    2,
                    .red,
                );
            },
        }
    }
};
