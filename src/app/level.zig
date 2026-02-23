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

// Just draw random tiles from tilemaps for now.
pub const LevelPlugin = struct {
    // keep as slice in case we want multiple layers
    tilesets: ?[]Tileset, // to randomly draw from, in order of addition to slice
    // player: *player.PlayerPlugin,
    bounds: rl.Vector2,
    bounds_min: rl.Vector2,

    pub fn update(self: *LevelPlugin) void {
        _ = self;

        std.debug.print("Level Plugin updating\n", .{});
    }

    pub fn draw(self: *LevelPlugin) void {
        std.debug.print("Level Plugin drawing\n", .{});

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

        self.drawTextures();
    }

    // generate array of tile indexes, to the count of the destination number of tiles.
    pub fn generateTextures(self: *LevelPlugin, alloc: std.mem.Allocator) !void {
        if (self.tilesets) |tilemaps| {
            for (tilemaps, 0..) |*tilemap, tmi| {
                const numTilesFrom = tilemap.cols * tilemap.rows;

                const width: i32 = @intFromFloat(self.bounds.x);
                const height: i32 = @intFromFloat(self.bounds.y);

                const numTilesToDraw: usize = @intCast(@divFloor(width, tilemap.tile_size) * @divFloor(height, tilemap.tile_size)); // assumes it starts at 0,0
                tilemap.generated_tiles = try alloc.alloc(i32, numTilesToDraw);

                std.debug.print("Generating tile {}/{}\n", .{ tmi, numTilesToDraw });

                if (tilemap.generated_tiles) |*gen| {
                    for (0..numTilesToDraw) |t| {
                        const randomTileIndex = rl.getRandomValue(0, numTilesFrom - 1);

                        // map the source tile to the destination tile
                        gen.*[@intCast(t)] = randomTileIndex;
                    }
                }
            }
        }
    }

    pub fn drawTextures(self: *LevelPlugin) void {
        // const randSeed = std.Random.float(@intFromFloat(rl.getTime()));

        if (self.tilesets) |tilemaps| {
            for (tilemaps) |tilemap| {
                if (tilemap.generated_tiles) |tiles| {
                    for (tiles) |tileNum| {
                        const row = @divFloor(tileNum, tilemap.cols);
                        const col = @mod(tileNum, tilemap.cols);

                        const x = col * tilemap.tile_size;
                        const y = row * tilemap.tile_size;

                        const i32CastTileNum: i32 = @intCast(tileNum);

                        const toX = @mod(i32CastTileNum, tilemap.tile_size) * tilemap.tile_size;
                        const toY = @divFloor(i32CastTileNum, tilemap.cols);
                        // (tileNum % tilemap.tile_size) / self.bounds.x) * tilemap.tile_size

                        rl.drawTextureRec(
                            tilemap.texture,
                            rl.Rectangle{
                                .x = @floatFromInt(x),
                                .y = @floatFromInt(y),
                                .width = @floatFromInt(tilemap.tile_size),
                                .height = @floatFromInt(tilemap.tile_size),
                            },
                            rl.Vector2{
                                .x = @floatFromInt(toX),
                                .y = @floatFromInt(toY),
                            },
                            rl.Color.white,
                        );
                    }
                }

                // self.drawTilemap(tilemap, num);
            }
        }
    }

    pub fn onUnload(self: *LevelPlugin, alloc: std.mem.Allocator) void {
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

        if (self.tilesets) |*tilemaps| {
            tilemaps.*[0] = Tileset{
                .texture = texture,
                .cols = 16,
                .rows = 16,
                .tile_size = 16,
                .generated_tiles = null,
            };

            generateTextures(self, alloc) catch unreachable;
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
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(LevelPlugin, &level, alloc);
}
