const std = @import("std");
const build_options = @import("build_options");
const collision = @import("collision.zig");

const Camera = @import("Camera.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const Vec3 = @import("Vec3.zig");

const Color = Vec3;
const HitList = collision.HitList;
const HitRecord = collision.HitRecord;
const Hittable = collision.Hittable;
const Point3 = Vec3;

pub fn main() !void {
    // Stdout
    const stdout_file = std.io.getStdOut().writer();
    var buffered_stdout = std.io.bufferedWriter(stdout_file);
    const stdout = buffered_stdout.writer();

    // Allocator
    var allocator_state = if (build_options.use_gpa)
        std.heap.GeneralPurposeAllocator(.{}){}
    else
        std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer {
        if (build_options.use_gpa)
            std.debug.assert(allocator_state.deinit() == .ok)
        else
            allocator_state.deinit();
    }

    const allocator = allocator_state.allocator();

    // Random number generator
    var rng = std.rand.DefaultPrng.init(1337);

    // World
    var world = Hittable{ .hit_list = HitList.init(allocator) };
    defer world.hit_list.deinit();

    try world.hit_list.add(Hittable{ .sphere = Sphere.new(Point3.new(0, 0, -1), 0.5) });
    try world.hit_list.add(Hittable{ .sphere = Sphere.new(Point3.new(0, -100.5, -1), 100) });

    // Camera
    const camera = Camera.new(16.0 / 9.0, 400, rng.random());

    // Debug output
    std.debug.print("Image width:  {d}\n", .{camera.image_width});
    std.debug.print("Image height: {d}\n", .{camera.image_height});

    // Render
    try camera.render(stdout, world);

    // Flush remaining buffer content
    try buffered_stdout.flush();
}
