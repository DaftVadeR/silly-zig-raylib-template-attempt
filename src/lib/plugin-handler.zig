const std = @import("std");
const plugin = @import("plugin.zig");

pub const PluginHandler = struct {
    plugins: std.array_list.Managed(plugin.Plugin),

    pub fn init(
        alloc: std.mem.Allocator,
    ) !PluginHandler {
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

    pub fn addPlugin(
        self: *PluginHandler,
        plug: plugin.Plugin,
    ) !void {
        try self.plugins.append(plug);
    }

    fn update(_: *PluginHandler) void {}
    fn draw(_: *PluginHandler) void {}

    pub fn baseUpdate(self: *PluginHandler) void {
        self.update();

        self.callPluginsUpdate();
    }

    pub fn baseDraw(self: *PluginHandler) void {
        self.draw();

        self.callPluginsDraw();
    }

    // FOR NOW, we draw in order of plugins added.
    pub fn callPluginsDraw(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.baseDraw();
        }
    }

    // FOR NOW, we update in order of plugins added.
    pub fn callPluginsUpdate(self: *PluginHandler) void {
        for (self.plugins.items) |*p| {
            p.baseUpdate();
        }
    }
};
