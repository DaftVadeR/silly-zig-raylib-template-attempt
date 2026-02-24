const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");
const player = @import("player.zig");
const common = @import("common.zig");

const Tileset = struct {
    texture: rl.Texture2D,
    cols: i32,
    rows: i32,
    tile_size: i32,
    generated_tiles: ?[]i32,
};

pub const WALL_SIZE: f32 = 50;

// Match the player's draw scale (player draws at 5.0 in player.zig:17)
const TILE_SCALE: f32 = 5.0;

// Just draw random tiles from tilemaps for now.
pub const LevelPlugin = struct {
    // keep as slice in case we want multiple layers
    tilesets: ?[]Tileset, // to randomly draw from, in order of addition to slice
    bounds: rl.Vector2,
    bounds_min: rl.Vector2,
    // Pre-rendered tilemap — drawn once, blitted each frame.
    render_texture: ?rl.RenderTexture2D,

    pub fn update(self: *LevelPlugin) void {
        _ = self;
    }

    pub fn draw(self: *LevelPlugin) void {
        // draw surrounding wall
        rl.drawRectangle(
            @intFromFloat(self.bounds_min.x - WALL_SIZE),
            @intFromFloat(self.bounds_min.y - WALL_SIZE),
            @intFromFloat(self.bounds.x + WALL_SIZE * 2),
            @intFromFloat(self.bounds.y + WALL_SIZE * 2),
            rl.Color.dark_brown,
        );

        rl.drawRectangle(
            @intFromFloat(self.bounds_min.x),
            @intFromFloat(self.bounds_min.y),
            @intFromFloat(self.bounds.x),
            @intFromFloat(self.bounds.y),
            rl.Color.green,
        );

        // Single draw call — blit the pre-rendered tilemap
        if (self.render_texture) |rt| {
            // RenderTexture2D is y-flipped in OpenGL, so we flip the source height
            rl.drawTexturePro(
                rt.texture,
                rl.Rectangle{
                    .x = 0,
                    .y = 0,
                    .width = @floatFromInt(rt.texture.width),
                    .height = -@as(f32, @floatFromInt(rt.texture.height)),
                },
                rl.Rectangle{
                    .x = self.bounds_min.x,
                    .y = self.bounds_min.y,
                    .width = self.bounds.x,
                    .height = self.bounds.y,
                },
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );
        }
    }

    // Generate array of random tile indexes for each tileset,
    // then pre-render them all onto a single RenderTexture2D.
    pub fn generateTextures(self: *LevelPlugin, alloc: std.mem.Allocator) !void {
        if (self.tilesets == null) return;
        const tilemaps = self.tilesets.?;

        // Scaled tile size in world units
        const tile_size = tilemaps[0].tile_size;
        const scaled_tile: f32 = @as(f32, @floatFromInt(tile_size)) * TILE_SCALE;

        // How many tiles fit across and down the world bounds
        const cols_per_row: i32 = @intFromFloat(self.bounds.x / scaled_tile);
        const rows_total: i32 = @intFromFloat(self.bounds.y / scaled_tile);
        const num_tiles: usize = @intCast(cols_per_row * rows_total);

        // Generate random tile indexes for each tileset
        for (tilemaps, 0..) |*tilemap, tmi| {
            const num_source_tiles = tilemap.cols * tilemap.rows;
            tilemap.generated_tiles = try alloc.alloc(i32, num_tiles);

            std.debug.print("Generating tileset {} - {d} tiles ({d} cols x {d} rows)\n", .{ tmi, num_tiles, cols_per_row, rows_total });

            if (tilemap.generated_tiles) |gen| {
                for (0..num_tiles) |t| {
                    gen[t] = rl.getRandomValue(0, num_source_tiles - 1);
                }
                std.debug.print("Generating done {d}\n", .{gen.len});
            }
        }

        // Pre-render all tiles onto a RenderTexture2D (once, not per frame)
        const rt_width: i32 = @intFromFloat(self.bounds.x);
        const rt_height: i32 = @intFromFloat(self.bounds.y);
        const rt = rl.loadRenderTexture(rt_width, rt_height) catch |err| {
            std.debug.print("Error loading render texture: {}\n", .{err});
            unreachable;
        };

        rl.beginTextureMode(rt);
        rl.clearBackground(rl.Color.blank);

        for (tilemaps) |tilemap| {
            if (tilemap.generated_tiles) |tiles| {
                for (tiles, 0..) |source_tile_idx, i| {
                    const idx: i32 = @intCast(i);

                    // Source rectangle: which tile in the tileset texture
                    const src_col = @mod(source_tile_idx, tilemap.cols);
                    const src_row = @divFloor(source_tile_idx, tilemap.cols);

                    // Dest position: where in the world grid
                    const dest_col = @mod(idx, cols_per_row);
                    const dest_row = @divFloor(idx, cols_per_row);

                    rl.drawTexturePro(
                        tilemap.texture,
                        rl.Rectangle{
                            .x = @floatFromInt(src_col * tile_size),
                            .y = @floatFromInt(src_row * tile_size),
                            .width = @floatFromInt(tile_size),
                            .height = @floatFromInt(tile_size),
                        },
                        rl.Rectangle{
                            .x = @as(f32, @floatFromInt(dest_col)) * scaled_tile,
                            .y = @as(f32, @floatFromInt(dest_row)) * scaled_tile,
                            .width = scaled_tile,
                            .height = scaled_tile,
                        },
                        rl.Vector2{ .x = 0, .y = 0 },
                        0,
                        rl.Color.white,
                    );
                }
            }
        }

        rl.endTextureMode();
        self.render_texture = rt;
    }

    pub fn onUnload(self: *LevelPlugin, alloc: std.mem.Allocator) void {
        if (self.render_texture) |rt| {
            rl.unloadRenderTexture(rt);
        }

        if (self.tilesets) |tilemaps| {
            for (tilemaps) |tilemap| {
                rl.unloadTexture(tilemap.texture);

                if (tilemap.generated_tiles) |tiles| {
                    alloc.free(tiles);
                }
            }

            alloc.free(tilemaps);
        }
    }

    pub fn onLoad(self: *LevelPlugin, alloc: std.mem.Allocator) void {
        std.debug.print("Level Plugin loaded\n", .{});

        self.tilesets = alloc.alloc(Tileset, 1) catch |err| {
            std.debug.print("Error allocating tilemaps: {}\n", .{err});
            unreachable;
        };

        const texture = rl.loadTexture("resources/images/level/tx_tileset_grass.png") catch |err| {
            std.debug.print("Error loading tilemap texture: {}\n", .{err});
            unreachable;
        };

        if (self.tilesets) |tilemaps| {
            tilemaps[0] = Tileset{
                .texture = texture,
                .cols = 16,
                .rows = 16,
                .tile_size = 16,
                .generated_tiles = null,
            };

            std.debug.print("allocating TileSets for : 0\n", .{});

            self.generateTextures(alloc) catch unreachable;
        }
    }
};

pub var level = LevelPlugin{
    .bounds_min = rl.Vector2{
        .x = 0,
        .y = 0,
    },
    .bounds = rl.Vector2{
        .x = 2000,
        .y = 2000,
    },
    .tilesets = null,
    .render_texture = null,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(LevelPlugin, &level, alloc);
}
