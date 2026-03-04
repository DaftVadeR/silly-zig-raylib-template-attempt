pub const ScreenSize = struct {
    x: i32,
    y: i32,
};

pub const P720 = ScreenSize{ .x = 1280, .y = 720 };
pub const P1080 = ScreenSize{ .x = 1920, .y = 1080 };

pub const ZOOM: f32 = 5;
