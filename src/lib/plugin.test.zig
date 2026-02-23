const std = @import("std");
const plugin = @import("plugin.zig");
const game = @import("game.zig");

// Two independent structs with their own instance state.
// Verifies that the comptime/opaque binding calls the correct method
// on the correct instance — not a shared global, not the wrong instance.

const MockA = struct {
    update_calls: usize = 0,
    draw_calls: usize = 0,
    load_calls: usize = 0,
    unload_calls: usize = 0,

    pub fn update(self: *MockA) void {
        self.update_calls += 1;
    }
    pub fn draw(self: *MockA) void {
        self.draw_calls += 1;
    }
    pub fn onLoad(self: *MockA, _: std.mem.Allocator) void {
        self.load_calls += 1;
    }
    pub fn onUnload(self: *MockA, _: std.mem.Allocator) void {
        self.unload_calls += 1;
    }
};

const MockB = struct {
    update_calls: usize = 0,
    draw_calls: usize = 0,
    load_calls: usize = 0,
    unload_calls: usize = 0,

    pub fn update(self: *MockB) void {
        self.update_calls += 1;
    }
    pub fn draw(self: *MockB) void {
        self.draw_calls += 1;
    }
    pub fn onLoad(self: *MockB, _: std.mem.Allocator) void {
        self.load_calls += 1;
    }
    pub fn onUnload(self: *MockB, _: std.mem.Allocator) void {
        self.unload_calls += 1;
    }
};

// -- Ordering helpers --
// Shared call log to verify plugins are invoked in registration order.
var call_order: [8]u8 = undefined;
var call_order_len: usize = 0;

fn resetCallOrder() void {
    call_order_len = 0;
}

fn recordCall(id: u8) void {
    if (call_order_len < call_order.len) {
        call_order[call_order_len] = id;
        call_order_len += 1;
    }
}

fn getCallOrder() []const u8 {
    return call_order[0..call_order_len];
}

const OrderedA = struct {
    pub fn update(_: *OrderedA) void {
        recordCall('A');
    }
    pub fn draw(_: *OrderedA) void {
        recordCall('A');
    }
    pub fn onLoad(_: *OrderedA, _: std.mem.Allocator) void {}
    pub fn onUnload(_: *OrderedA, _: std.mem.Allocator) void {}
};

const OrderedB = struct {
    pub fn update(_: *OrderedB) void {
        recordCall('B');
    }
    pub fn draw(_: *OrderedB) void {
        recordCall('B');
    }
    pub fn onLoad(_: *OrderedB, _: std.mem.Allocator) void {}
    pub fn onUnload(_: *OrderedB, _: std.mem.Allocator) void {}
};

// -- Tests --

test "plugin update and draw call the bound instance" {
    var a = MockA{};

    var p = try plugin.Plugin.init(MockA, &a, std.testing.allocator);
    defer p.deinit(std.testing.allocator);

    p.update();
    p.update();
    p.draw();

    try std.testing.expectEqual(@as(usize, 2), a.update_calls);
    try std.testing.expectEqual(@as(usize, 1), a.draw_calls);
}

test "onLoad is called on the bound instance when added to a plugin handler" {
    var a = MockA{};
    var b = MockB{};

    var g = try game.Game.init(MockA, &a, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(MockB, &b, std.testing.allocator));

    // onLoad fires once at add time, not during update/draw
    try std.testing.expectEqual(@as(usize, 1), b.load_calls);
    try std.testing.expectEqual(@as(usize, 0), b.update_calls);
    try std.testing.expectEqual(@as(usize, 0), b.draw_calls);
}

test "onUnload is called when plugin is deinited" {
    var a = MockA{};

    var p = try plugin.Plugin.init(MockA, &a, std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 0), a.unload_calls);

    p.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), a.unload_calls);
}

test "two plugins with different types call their own instances independently" {
    var a = MockA{};
    var b = MockB{};

    var g = try game.Game.init(MockA, &a, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(MockB, &b, std.testing.allocator));

    g.update();
    g.draw();

    try std.testing.expectEqual(@as(usize, 1), a.update_calls);
    try std.testing.expectEqual(@as(usize, 1), a.draw_calls);
    try std.testing.expectEqual(@as(usize, 1), b.update_calls);
    try std.testing.expectEqual(@as(usize, 1), b.draw_calls);
}

test "two plugins of the same type each have independent instance state" {
    var a1 = MockA{};
    var a2 = MockA{};

    var g = try game.Game.init(MockA, &a1, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(MockA, &a2, std.testing.allocator));

    g.update();
    g.update();

    try std.testing.expectEqual(@as(usize, 2), a1.update_calls);
    try std.testing.expectEqual(@as(usize, 2), a2.update_calls);
    try std.testing.expectEqual(@as(usize, 0), a1.draw_calls);
    try std.testing.expectEqual(@as(usize, 0), a2.draw_calls);
}

test "plugins update and draw in addPlugin registration order" {
    resetCallOrder();

    var root = MockA{};
    var oa = OrderedA{};
    var ob = OrderedB{};

    var g = try game.Game.init(MockA, &root, std.testing.allocator);
    defer g.deinit();

    try g.plugin_handler.addPlugin(try plugin.Plugin.init(OrderedA, &oa, std.testing.allocator));
    try g.plugin_handler.addPlugin(try plugin.Plugin.init(OrderedB, &ob, std.testing.allocator));

    // one update cycle: should call A then B
    g.update();
    try std.testing.expectEqualSlices(u8, "AB", getCallOrder());

    // reset and test draw order
    resetCallOrder();
    g.draw();
    try std.testing.expectEqualSlices(u8, "AB", getCallOrder());
}
