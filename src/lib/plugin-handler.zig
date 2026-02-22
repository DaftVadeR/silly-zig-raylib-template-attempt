const std = @import("std");
const plugin = @import("plugin.zig");

pub const PluginHandler = struct {
    plugins: std.array_list.Managed(plugin.Plugin),

    pub fn init(alloc: std.mem.Allocator) !PluginHandler {
        return PluginHandler{
            .plugins = std.array_list.Managed(plugin.Plugin).init(alloc),
        };
    }

    pub fn deinit(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.deinit();
        }
        self.plugins.deinit();
    }

    pub fn addPlugin(self: *PluginHandler, p: plugin.Plugin) !void {
        try self.plugins.append(p);
        const added = &self.plugins.items[self.plugins.items.len - 1];
        try added.load(self.plugins.allocator);
    }

    pub fn update(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.update();
        }
    }

    pub fn draw(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.draw();
        }
    }
};
