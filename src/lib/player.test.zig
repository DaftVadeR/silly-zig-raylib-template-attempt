const std = @import("std");
const plugin = @import("plugin.zig");
const game = @import("game.zig");

// A plain test stand-in for PlayerPlugin — same shape, no raylib dependency.
const MockPlayer = struct {
    speed: u16,
    x: f32,
    update_calls: usize,
    draw_calls: usize,

    pub fn update(self: *MockPlayer) void {
        self.x += @floatFromInt(self.speed);
        self.update_calls += 1;
    }

    pub fn draw(self: *MockPlayer) void {
        self.draw_calls += 1;
    }
};

// A minimal game root — just counts calls so we can verify the cascade.
const MockGame = struct {
    update_calls: usize,
    draw_calls: usize,

    pub fn update(self: *MockGame) void {
        self.update_calls += 1;
    }

    pub fn draw(self: *MockGame) void {
        self.draw_calls += 1;
    }
};

test "plugin calls update and draw on the bound instance" {
    var player = MockPlayer{ .speed = 10, .x = 0, .update_calls = 0, .draw_calls = 0 };

    var p = try plugin.Plugin.init(MockPlayer, &player, std.testing.allocator);
    defer p.deinit();

    p.update();
    p.update();
    p.draw();

    // state was mutated on the real instance
    try std.testing.expectEqual(@as(f32, 20), player.x);
    try std.testing.expectEqual(@as(usize, 2), player.update_calls);
    try std.testing.expectEqual(@as(usize, 1), player.draw_calls);
}

test "game propagates update and draw to a bound plugin instance" {
    var root = MockGame{ .update_calls = 0, .draw_calls = 0 };
    var player = MockPlayer{ .speed = 5, .x = 0, .update_calls = 0, .draw_calls = 0 };

    var g = try game.Game.init(MockGame, &root, std.testing.allocator);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(MockPlayer, &player, std.testing.allocator));

    g.update();
    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 2), root.update_calls);
    try std.testing.expectEqual(@as(usize, 1), root.draw_calls);

    try std.testing.expectEqual(@as(f32, 10), player.x);
    try std.testing.expectEqual(@as(usize, 2), player.update_calls);
    try std.testing.expectEqual(@as(usize, 1), player.draw_calls);
}
