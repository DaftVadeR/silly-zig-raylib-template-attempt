const rl = @import("raylib");
const std = @import("std");

// pub const AnimGroup = struct {
//     anims: []SpriteAnim,
// };

pub const SpriteAnim = struct {
    texture: rl.Texture2D,
    frameW: f32,
    frameH: f32,
    cols: usize,
    totalFrames: usize,
    fps: f32 = 12.0,
    currentFrame: usize = 0,
    timer: f32 = 0.0,

    pub fn init(
        texture: rl.Texture2D,
        frameW: f32,
        frameH: f32,
        cols: usize,
        totalFrames: usize,
        fps: f32,
    ) !SpriteAnim {
        return SpriteAnim{
            .frameW = frameW,
            .frameH = frameH,
            .cols = cols,
            .totalFrames = totalFrames,
            .fps = fps,
            .texture = texture, // Texture loading
        };
    }

    pub fn denit(self: *SpriteAnim) void {
        rl.unloadTexture(self.texture);
        // allocator.destroy(self)
    }

    pub fn update(self: *SpriteAnim, dt: f32) void {
        self.timer += dt;
        if (self.timer >= 1.0 / self.fps) {
            self.timer = 0; // or -= 1/fps for perfect timing
            self.currentFrame = (self.currentFrame + 1) % self.totalFrames;
        }
    }

    pub fn draw(self: SpriteAnim, pos: rl.Vector2, scale: f32, tint: rl.Color) void {
        const col = self.currentFrame % self.cols;
        const row = self.currentFrame / self.cols;
        const src = rl.Rectangle{
            .x = @as(f32, @floatFromInt(col)) * self.frameW,
            .y = @as(f32, @floatFromInt(row)) * self.frameH,
            .width = self.frameW,
            .height = self.frameH,
        };

        const dest = rl.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = self.frameW * scale,
            .height = self.frameH * scale,
        };

        rl.drawTexturePro(self.texture, src, dest, rl.Vector2{ .x = 0, .y = 0 }, 0, tint);
    }
};
