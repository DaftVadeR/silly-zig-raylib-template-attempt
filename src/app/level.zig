const std = @import("std");
const rl = @import("raylib");
const plugin = @import("../lib/plugin.zig");

const Tileset = struct {
    texture: rl.Texture2D,
    cols: i32,
    rows: i32,
    tile_size: i32,
    generated_tiles: ?[]i32,
};

const GridSize = struct {
    cols: i32,
    rows: i32,
    count: usize,
};

pub const WALL_SIZE: f32 = 10;

pub const LevelPlugin = struct {
    tilesets: ?[]Tileset,
    bounds: rl.Vector2,
    bounds_min: rl.Vector2,
    render_texture: ?rl.RenderTexture2D,

    pub fn update(self: *LevelPlugin) void {
        _ = self;
    }

    pub fn draw(self: *LevelPlugin) void {
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

        self.drawCombinedTexture();
    }

    pub fn processTextures(self: *LevelPlugin, alloc: std.mem.Allocator) !void {
        try self.generateTileIndexes(alloc);
        try self.renderCombinedTilemap();
    }

    fn getGridSize(self: *LevelPlugin, tile_size: i32) GridSize {
        const cols: i32 = @intFromFloat(self.bounds.x / @as(f32, @floatFromInt(tile_size)));
        const rows: i32 = @intFromFloat(self.bounds.y / @as(f32, @floatFromInt(tile_size)));

        return GridSize{
            .cols = cols,
            .rows = rows,
            .count = @intCast(cols * rows),
        };
    }

    fn generateTileIndexes(self: *LevelPlugin, alloc: std.mem.Allocator) !void {
        if (self.tilesets == null) return;
        const tilesets = self.tilesets.?;

        for (tilesets, 0..) |*tileset, tileset_index| {
            const grid = self.getGridSize(tileset.tile_size);
            const source_tile_count = tileset.cols * tileset.rows;

            tileset.generated_tiles = try alloc.alloc(i32, grid.count);

            std.debug.print("Generating tileset {} - {d} tiles ({d} cols x {d} rows)\n", .{
                tileset_index,
                grid.count,
                grid.cols,
                grid.rows,
            });

            if (tileset.generated_tiles) |tiles| {
                for (0..grid.count) |i| {
                    tiles[i] = rl.getRandomValue(0, source_tile_count - 1);
                }

                std.debug.print("Generating done {d}\n", .{tiles.len});
            }
        }
    }

    fn drawTileToTarget(_: *LevelPlugin, tileset: Tileset, source_tile_index: i32, dest_col: i32, dest_row: i32) void {
        const tile_size = tileset.tile_size;
        const tile_size_f: f32 = @floatFromInt(tile_size);

        const source_col = @mod(source_tile_index, tileset.cols);
        const source_row = @divFloor(source_tile_index, tileset.cols);

        const source = rl.Rectangle{
            .x = @as(f32, @floatFromInt(source_col * tile_size)),
            .y = @as(f32, @floatFromInt(source_row * tile_size)),
            .width = tile_size_f,
            .height = tile_size_f,
        };

        const destination = rl.Rectangle{
            .x = @as(f32, @floatFromInt(dest_col)) * tile_size_f,
            .y = @as(f32, @floatFromInt(dest_row)) * tile_size_f,
            .width = tile_size_f,
            .height = tile_size_f,
        };

        rl.drawTexturePro(
            tileset.texture,
            source,
            destination,
            rl.Vector2{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );
    }

    fn renderCombinedTilemap(self: *LevelPlugin) !void {
        if (self.tilesets == null) return;
        const tilesets = self.tilesets.?;

        const width: i32 = @intFromFloat(self.bounds.x);
        const height: i32 = @intFromFloat(self.bounds.y);

        const target = try rl.loadRenderTexture(width, height);

        rl.beginTextureMode(target);
        rl.clearBackground(rl.Color.blank);

        for (tilesets) |tileset| {
            if (tileset.generated_tiles) |tiles| {
                const grid = self.getGridSize(tileset.tile_size);

                for (tiles, 0..) |source_tile_index, i| {
                    const tile_index: i32 = @intCast(i);
                    const dest_col = @mod(tile_index, grid.cols);
                    const dest_row = @divFloor(tile_index, grid.cols);

                    self.drawTileToTarget(tileset, source_tile_index, dest_col, dest_row);
                }
            }
        }

        rl.endTextureMode();
        self.render_texture = target;
    }

    fn drawCombinedTexture(self: *LevelPlugin) void {
        if (self.render_texture) |rt| {
            rl.drawTexturePro(
                rt.texture,
                rl.Rectangle{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(rt.texture.width)),
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

    pub fn onUnload(self: *LevelPlugin, alloc: std.mem.Allocator) void {
        if (self.render_texture) |rt| {
            rl.unloadRenderTexture(rt);
        }

        if (self.tilesets) |tilesets| {
            for (tilesets) |tileset| {
                rl.unloadTexture(tileset.texture);

                if (tileset.generated_tiles) |tiles| {
                    alloc.free(tiles);
                }
            }

            alloc.free(tilesets);
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

        if (self.tilesets) |tilesets| {
            tilesets[0] = Tileset{
                .texture = texture,
                .cols = 16,
                .rows = 16,
                .tile_size = 16,
                .generated_tiles = null,
            };

            std.debug.print("allocating TileSets for : 0\n", .{});
            self.processTextures(alloc) catch unreachable;
        }
    }
};

pub var level = LevelPlugin{
    .bounds_min = rl.Vector2{ .x = 0, .y = 0 },
    .bounds = rl.Vector2{ .x = 2000, .y = 2000 },
    .tilesets = null,
    .render_texture = null,
};

pub fn createPlugin(alloc: std.mem.Allocator) !plugin.Plugin {
    return plugin.Plugin.init(LevelPlugin, &level, alloc);
}
