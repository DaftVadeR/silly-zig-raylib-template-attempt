const std = @import("std");
const rl = @import("raylib");
const builtin = @import("builtin");

const is_wasm = builtin.os.tag == .emscripten;

// framework files
const game = @import("./lib/game.zig");
const plugin = @import("./lib/plugin.zig");
const plugin_handler = @import("./lib/plugin-handler.zig");

// constant values
const common = @import("./app/common.zig");

// game file plugins
const player = @import("./app/player.zig");
const level = @import("./app/level.zig");
const player_movement = @import("./app/player-movement.zig");
// const camera = @import("./app/camera.zig");

const AppRoot = struct {
    pub fn update(_: *AppRoot) void {
        // std.debug.print("UPDATING\n", .{});
    }
    pub fn draw(_: *AppRoot) void {
        // std.debug.print("DRAWING\n", .{});
    }
    pub fn onLoad(_: *AppRoot, _: std.mem.Allocator) !void {}
};

var app_root = AppRoot{};

// ---- Global state (needed for the emscripten callback) ----
var g: game.Game = undefined;
var camera2d: rl.Camera2D = undefined;

fn initGame(alloc: std.mem.Allocator) !void {
    g = try game.Game.init(AppRoot, &app_root, alloc);

    try g.plugin_handler.addPlugin(try level.createPlugin(alloc));
    try g.plugin_handler.addPlugin(try player_movement.createPlugin(alloc));
    try g.plugin_handler.addPlugin(try player.createPlugin(alloc));

    // broken
    // try g.plugin_handler.addPlugin(try camera.createPlugin(alloc));

    camera2d = rl.Camera2D{
        .target = player.player.position,
        .offset = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };
}

fn updateDrawFrame() callconv(.c) void {
    g.update();

    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.ray_white);

    camera2d.begin();

    camera2d.offset = rl.Vector2{ .x = common.P1080.x / 2.0, .y = common.P1080.y / 2.0 };
    camera2d.target = player.player.position;

    g.draw();

    camera2d.end();
}

pub fn main() anyerror!void {
    const screenWidth = common.P1080.x;
    const screenHeight = common.P1080.y;

    rl.initWindow(screenWidth, screenHeight, "Simple Zig template");

    if (is_wasm) {
        // WASM path: c_allocator (backed by emmalloc), emscripten main loop callback.
        // main() returns after setting the loop — no defers for cleanup.
        const allocator = std.heap.c_allocator;

        try initGame(allocator);

        const emscripten = std.os.emscripten;
        emscripten.emscripten_set_main_loop(updateDrawFrame, 0, 1);
    } else {
        // Native path: DebugAllocator, blocking while loop, full cleanup.
        rl.toggleFullscreen();
        rl.setTargetFPS(120);

        defer rl.closeWindow();

        var dba: std.heap.DebugAllocator(.{}) = .init;
        defer _ = dba.deinit();
        const allocatorBase = dba.allocator();

        var arena = std.heap.ArenaAllocator.init(allocatorBase);
        defer arena.deinit();

        const allocator = arena.allocator();

        try initGame(allocator);
        defer g.deinit();

        while (!rl.windowShouldClose()) {
            updateDrawFrame();
        }
    }
}
