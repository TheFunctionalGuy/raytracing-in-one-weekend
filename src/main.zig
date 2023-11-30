const std = @import("std");
const build_options = @import("build_options");
const collision = @import("collision.zig");

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

    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;

    const image_width: usize = 400;
    const image_height: usize = blk: {
        const height: usize = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);

        if (height > 1) {
            break :blk height;
        } else {
            break :blk 1;
        }
    };

    // World
    var world = Hittable{ .hit_list = HitList.init(allocator) };
    defer world.hit_list.deinit();

    try world.hit_list.add(Hittable{ .sphere = Sphere.new(Point3.new(0, 0, -1), 0.5) });
    try world.hit_list.add(Hittable{ .sphere = Sphere.new(Point3.new(0, -100.5, -1), 100) });

    // Camera
    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const viewport_width: f64 = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));
    const camera_center = Point3.default();

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec3.new(viewport_width, 0, 0);
    const viewport_v = Vec3.new(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = camera_center
        .sub(Vec3.new(0, 0, focal_length))
        .sub(viewport_u.mul_scalar(0.5))
        .sub(viewport_v.mul_scalar(0.5));

    const pixel_00_loc = viewport_upper_left
        .add(pixel_delta_u.add(pixel_delta_v).mul_scalar(0.5));

    // Debug output
    std.debug.print("Image width:  {d}\n", .{image_width});
    std.debug.print("Image height: {d}\n", .{image_height});

    // Render
    // Header
    try stdout.print("P3\n", .{});
    try stdout.print("{d} {d}\n", .{ image_width, image_height });
    try stdout.print("255\n", .{});

    // Data
    for (0..image_height) |h| {
        std.debug.print("\rScanlines remaining: {}", .{image_height - h});

        for (0..image_width) |w| {
            const pixel_center = pixel_00_loc
                .add(pixel_delta_u.mul_scalar(@floatFromInt(w)))
                .add(pixel_delta_v.mul_scalar(@floatFromInt(h)));
            const ray_direction = pixel_center.sub(camera_center);

            const ray = Ray.new(camera_center, ray_direction);
            const pixel_color = ray_color(ray, world);

            try stdout.print("{}\n", .{pixel_color});
        }
    }
    std.debug.print("\rDone.                                                    \n", .{});

    // Flush remaining buffer content
    try buffered_stdout.flush();
}

fn ray_color(ray: Ray, world: Hittable) Color {
    var record = HitRecord{};

    if (world.hit(ray, Interval.new(0, std.math.inf(f64)), &record)) {
        return record.normal
            .add(Color.new(1, 1, 1))
            .mul_scalar(0.5);
    }

    const unit_direction = ray.direction.unit_vector();
    const a = 0.5 * (unit_direction.y() + 1.0);

    const start_color = Color.new(1, 1, 1);
    const end_color = Color.new(0.5, 0.7, 1.0);

    // Do a linear interpolation (lerp)
    return start_color
        .mul_scalar(1.0 - a)
        .add(end_color.mul_scalar(a));
}
