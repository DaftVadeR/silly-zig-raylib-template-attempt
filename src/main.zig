const std = @import("std");
const rl = @import("raylib");
const game = @import("./lib/game.zig");
const player = @import("./app/player.zig");
const player_movement = @import("./app/player-movement.zig");
const plugin = @import("./lib/plugin.zig");
const plugin_handler = @import("./lib/plugin-handler.zig");

const AppRoot = struct {
    pub fn update(_: *AppRoot) void {
        std.debug.print("UPDATING\n", .{});
    }
    pub fn draw(_: *AppRoot) void {
        std.debug.print("DRAWING\n", .{});
    }
    pub fn onLoad(_: *AppRoot, _: std.mem.Allocator) !void {}
};

var app_root = AppRoot{};

fn getGame(alloc: std.mem.Allocator) !game.Game {
    var g = try game.Game.init(AppRoot, &app_root, alloc);
    try g.plugin_handler.addPlugin(try player.createPlugin(alloc));
    try g.plugin_handler.addPlugin(try player_movement.createPlugin(alloc));

    return g;
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(2); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var dba: std.heap.DebugAllocator(.{}) = .init;
    defer _ = dba.deinit();
    const allocatorBase = dba.allocator();

    // use page allocator later as base, with arena on top
    var arena = std.heap.ArenaAllocator.init(allocatorBase);
    defer arena.deinit();

    const allocator = arena.allocator();

    var g = try getGame(allocator);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //
        //----------------------------------------------------------------------------------
        g.update();

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        g.draw();

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }

    g.deinit();
}
