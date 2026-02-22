const std = @import("std");

pub const Game = struct {
    allocator: std.mem.Allocator,
    plugin_handler: PluginHandler,

    pub fn init(alloc: std.mem.Allocator) !Game {
        return Game{
            .allocator = alloc,
            .plugin_handler = try PluginHandler.init(alloc),
        };
    }

    pub fn deinit(self: *Game) void {
        self.plugin_handler.deinit();
    }
};

pub const PluginHandler = struct {
    plugins: std.array_list.Managed(Plugin),

    pub fn init(alloc: std.mem.Allocator) !PluginHandler {
        return PluginHandler{
            .plugins = std.array_list.Managed(Plugin).init(alloc),
        };
    }

    pub fn deinit(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.deinit();
        }

        self.plugins.deinit();
    }

    pub fn addPlugin(self: *PluginHandler, plugin: Plugin) !void {
        try self.plugins.append(plugin);
    }
};

pub const Plugin = struct {
    allocator: std.mem.Allocator,
    plugin_handler: PluginHandler,

    pub fn init(alloc: std.mem.Allocator) !Plugin {
        return Plugin{
            .allocator = alloc,
            .plugin_handler = try PluginHandler.init(alloc),
        };
    }

    pub fn deinit(self: *Plugin) void {
        self.plugin_handler.deinit();
    }
};

// pub fn getGame(allocator: std.mem.Allocator) Game{
//    return Game {
//        .allocator = allocator,
//        .plugins =
//    };
// }
