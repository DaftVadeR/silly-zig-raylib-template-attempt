const std = @import("std");
const plugin = @import("plugin.zig");
const game = @import("game.zig");

// Two independent structs with their own instance state.
// Verifies that the comptime/opaque binding calls the correct method
// on the correct instance — not a shared global, not the wrong instance.

const MockA = struct {
    update_calls: usize = 0,
    draw_calls: usize = 0,

    pub fn update(self: *MockA) void {
        self.update_calls += 1;
    }

    pub fn draw(self: *MockA) void {
        self.draw_calls += 1;
    }
};

const MockB = struct {
    update_calls: usize = 0,
    draw_calls: usize = 0,

    pub fn update(self: *MockB) void {
        self.update_calls += 1;
    }

    pub fn draw(self: *MockB) void {
        self.draw_calls += 1;
    }
};

test "plugin update and draw call the bound instance" {
    var a = MockA{};

    var p = try plugin.Plugin.init(MockA, &a, std.testing.allocator);
    defer p.deinit();

    p.update();
    p.update();
    p.draw();

    try std.testing.expectEqual(@as(usize, 2), a.update_calls);
    try std.testing.expectEqual(@as(usize, 1), a.draw_calls);
}

test "two plugins with different types call their own instances independently" {
    var a = MockA{};
    var b = MockB{};

    var g = try game.Game.init(MockA, &a, std.testing.allocator);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(MockB, &b, std.testing.allocator));

    g.update();
    g.draw();

    // a is the game root
    try std.testing.expectEqual(@as(usize, 1), a.update_calls);
    try std.testing.expectEqual(@as(usize, 1), a.draw_calls);

    // b is the plugin — must have been called independently
    try std.testing.expectEqual(@as(usize, 1), b.update_calls);
    try std.testing.expectEqual(@as(usize, 1), b.draw_calls);
}

test "two plugins of the same type each have independent instance state" {
    var a1 = MockA{};
    var a2 = MockA{};

    var g = try game.Game.init(MockA, &a1, std.testing.allocator);
    defer g.deinit();

    try g.addPlugin(try plugin.Plugin.init(MockA, &a2, std.testing.allocator));

    g.update();
    g.update();

    // a1 is the game root, a2 is the plugin — same type, different instances
    try std.testing.expectEqual(@as(usize, 2), a1.update_calls);
    try std.testing.expectEqual(@as(usize, 2), a2.update_calls);

    // draw was never called — confirm neither instance registered any
    try std.testing.expectEqual(@as(usize, 0), a1.draw_calls);
    try std.testing.expectEqual(@as(usize, 0), a2.draw_calls);
}
