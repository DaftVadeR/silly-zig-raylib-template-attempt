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

var screenWidth = common.P720.x;
var screenHeight = common.P720.y;

var screenWidthFloat: f32 = @floatFromInt(common.P720.x);
var screenHeightFloat: f32 = @floatFromInt(common.P720.y);

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
        .zoom = common.ZOOM,
    };
}

fn updateDrawFrameForWasm() callconv(.c) void {
    updateDrawFrame();
}

fn updateDrawFrame() void {
    g.update();

    rl.beginDrawing();

    rl.clearBackground(.ray_white);

    camera2d.begin();

    camera2d.offset = rl.Vector2{ .x = screenWidthFloat / 2.0, .y = screenHeightFloat / 2.0 };
    camera2d.target = player.player.position;

    g.draw();

    camera2d.end();

    rl.endDrawing();
}

pub fn main() anyerror!void {
    if (is_wasm) {
        rl.setTargetFPS(60);

        rl.setConfigFlags(.{
            .vsync_hint = true,
            .msaa_4x_hint = false,
        });

        rl.initWindow(
            screenWidth,
            screenHeight,
            "Simple Zig template",
        );

        // WASM path: c_allocator (backed by emmalloc), emscripten main loop callback.
        // main() returns after setting the loop — no defers for cleanup.
        const allocator = std.heap.c_allocator;

        try initGame(allocator);

        const emscripten = std.os.emscripten;

        emscripten.emscripten_set_main_loop(updateDrawFrameForWasm, 0, 1);
    } else {
        screenWidth = common.P1080.x;
        screenHeight = common.P1080.y;

        screenWidthFloat = @floatFromInt(common.P1080.x);
        screenHeightFloat = @floatFromInt(common.P1080.y);

        rl.setTargetFPS(60);

        rl.setConfigFlags(.{
            .vsync_hint = true,
            .msaa_4x_hint = false,
        });

        rl.initWindow(screenWidth, screenHeight, "Simple Zig template");

        // Native path: DebugAllocator, blocking while loop, full cleanup.
        rl.toggleFullscreen();

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
