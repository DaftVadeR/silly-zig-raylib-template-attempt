const std = @import("std");

const PLUGIN_ALLOCATION_INCREMENTS = 10;

const Game = struct {
    allocator: std.mem.Allocator,
    plugin_handler: PluginHandler,

    pub fn init(alloc: std.mem.Allocator) !Game {
        return Game{
            .allocator = alloc,
            .plugin_handler = PluginHandler.init(alloc),
        };
    }
};

const PluginHandler = struct {
    allocator: std.mem.Allocator,
    plugins_allocated: u16,
    plugins_added: u16,
    plugins: []Plugin,

    pub fn init(alloc: std.mem.Allocator) !PluginHandler {
        const plugins = try alloc.alloc(Plugin, PLUGIN_ALLOCATION_INCREMENTS);

        return PluginHandler{
            .allocator = alloc,
            .plugins = plugins,
            .plugins_added = 0,
            .plugins_allocated = plugins.len,
        };
    }

    pub fn deinit(self: PluginHandler) !void {
        for (self.plugins) |plugin| {
            plugin.deinit();
        }

        self.allocator.free(self.plugins);
    }

    pub fn addPlugin(self: PluginHandler, plugin: Plugin) !void {
        //defensive coding but hey.
        if (self.plugins_added >= self.plugins_allocated) {
            try reAllocatePlugins();
        }

        self.plugins[self.plugins_added] = plugin;
    }

    pub fn reAllocatePlugins(self: PluginHandler) !void {
        const newPlugins = try self.allocator.alloc(
            Plugin,
            self.plugins_allocated + PLUGIN_ALLOCATION_INCREMENTS,
        );

        // allocate to new slice
        for (self.plugins_added, 0..) |p, i| {
            newPlugins[i] = p;
        }

        // replace
        self.plugins = newPlugins;
    }
};

const Plugin = struct {
    allocator: std.mem.Allocator,
    plugin_handler: PluginHandler,

    pub fn init(alloc: std.mem.Allocator) !Plugin {
        return Plugin{
            .allocator = alloc,
            .plugin_handler = try PluginHandler.init(alloc),
        };
    }

    pub fn deinit(self: *Plugin) !void {
        self.plugin_handler.deinit();
    }
};

// pub fn getGame(allocator: std.mem.Allocator) Game{
//    return Game {
//        .allocator = allocator,
//        .plugins =
//    };
// }
