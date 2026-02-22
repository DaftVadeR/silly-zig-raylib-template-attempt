// DOESNT WORK - MAYBE LATER WE CAN ADD A FACILITY FOR THIS
//
// const std = @import("std");
// const rl = @import("raylib");
// const plugin = @import("../lib/plugin.zig");
// const player = @import("player.zig");
// const common = @import("common.zig");
//
// var camera2d = rl.Camera2D{
//     .target = .{ .x = 0, .y = 0 },
//     .offset = .{ .x = 0, .y = 0 },
//     .rotation = 0,
//     .zoom = 1,
// };
//
// // Handles movement input and animation state only — no player data ownership.
// const CameraPlugin = struct {
//     player: *player.PlayerPlugin,
//     camera: *rl.Camera2D,
//
//     pub fn update(self: *CameraPlugin) void {
//         // _ = self;
//         std.debug.print("CameraPlugin updating {}\n", .{self.player.position});
//         self.camera.target = self.player.position;
//     }
//
//     pub fn draw(_: *CameraPlugin) void {
//         std.debug.print("CameraPlugin drawing\n", .{});
//     }
//
//     pub fn onLoad(self: *CameraPlugin, _: std.mem.Allocator) !void {
//         std.debug.print("CameraPlugin loaded\n", .{});
//
//         self.camera.begin();
//
//         self.camera.offset = rl.Vector2{ .x = common.P1080.x / 2.0, .y = common.P1080.y / 2.0 };
//         // latestTarget = self.player.position;
//     }
// };
//
// pub var camera = CameraPlugin{
//     .player = &player.player,
//     .camera = &camera2d,
// };
//
// pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
//     return plugin.Plugin.init(CameraPlugin, &camera, alloc);
// }
