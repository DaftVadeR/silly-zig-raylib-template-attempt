const rl = @import("raylib");

pub const SpriteAnim = struct {
    // Borrowed — the caller loads and owns the texture.
    texture: *const rl.Texture2D,
    frame_w: f32,
    frame_h: f32,
    cols: usize,
    // Index of the first frame in this animation on the sheet.
    from_frame: usize,
    // Total number of frames in this animation.
    total_frames: usize,
    // Playback speed.
    fps: f32,
    // Mutable playback state.
    current_frame: usize,
    timer: f32,

    pub fn init(
        texture: *const rl.Texture2D,
        frameW: f32,
        frameH: f32,
        cols: usize,
        fromFrame: usize,
        totalFrames: usize,
        fps: f32,
    ) SpriteAnim {
        return SpriteAnim{
            .texture = texture,
            .frame_w = frameW,
            .frame_h = frameH,
            .cols = cols,
            .from_frame = fromFrame,
            .total_frames = totalFrames,
            .fps = fps,
            .current_frame = 0,
            .timer = 0,
        };
    }

    pub fn update(self: *SpriteAnim, dt: f32) void {
        self.timer += dt;

        if (self.timer >= 1.0 / self.fps) {
            self.timer -= 1.0 / self.fps;
            self.current_frame = (self.current_frame + 1) % self.total_frames;
        }
    }

    /// facingX: 1 = right (default), -1 = left (flips horizontally)
    pub fn draw(self: SpriteAnim, pos: rl.Vector2, tint: rl.Color, facingX: f32) void {
        const actualFrame = self.from_frame + self.current_frame;
        const col = actualFrame % self.cols;
        const row = actualFrame / self.cols;

        // A negative src width tells drawTexturePro to flip the frame horizontally.
        const srcW = self.frame_w * facingX;

        const src = rl.Rectangle{
            .x = @as(f32, @floatFromInt(col)) * self.frame_w,
            .y = @as(f32, @floatFromInt(row)) * self.frame_h,
            .width = srcW,
            .height = self.frame_h,
        };

        const dest = rl.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = self.frame_w,
            .height = self.frame_h,
        };

        rl.drawTexturePro(
            self.texture.*,
            src,
            dest,
            rl.Vector2{ .x = 0, .y = 0 },
            0,
            tint,
        );
    }
};
