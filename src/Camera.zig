const std = @import("std");
const collision = @import("collision.zig");

const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Color = Vec3;
const HitRecord = collision.HitRecord;
const Hittable = collision.Hittable;
const Point3 = Vec3;
const Random = std.rand.Random;

aspect_ratio: f64,

image_width: usize,
image_height: usize,

center: Point3,
pixel_00_loc: Point3,

pixel_delta_u: Vec3,
pixel_delta_v: Vec3,

samples_per_pixel: usize = 100,
rand: Random,

const Self = @This();

pub fn new(aspect_ratio: f64, image_width: usize, rand: Random) Self {
    const image_height: usize = blk: {
        const height: usize = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);

        if (height > 1) {
            break :blk height;
        } else {
            break :blk 1;
        }
    };

    const center = Point3.default();

    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const viewport_width: f64 = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec3.new(viewport_width, 0, 0);
    const viewport_v = Vec3.new(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = center
        .sub(Vec3.new(0, 0, focal_length))
        .sub(viewport_u.mul_scalar(0.5))
        .sub(viewport_v.mul_scalar(0.5));

    const pixel_00_loc = viewport_upper_left
        .add(pixel_delta_u.add(pixel_delta_v).mul_scalar(0.5));

    return .{
        .aspect_ratio = aspect_ratio,
        .image_width = image_width,
        .image_height = image_height,
        .center = center,
        .pixel_00_loc = pixel_00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .rand = rand,
    };
}

pub fn render(self: Self, writer: anytype, world: Hittable) !void {
    // Header
    try writer.print("P3\n", .{});
    try writer.print("{d} {d}\n", .{ self.image_width, self.image_height });
    try writer.print("255\n", .{});

    // Data
    for (0..self.image_height) |h| {
        std.debug.print("\rScanlines remaining: {}", .{self.image_height - h});

        for (0..self.image_width) |w| {
            var pixel_color = Color.default();

            for (0..self.samples_per_pixel) |_| {
                const ray = self.sample_camera_ray(w, h);
                pixel_color = pixel_color.add(ray_color(ray, world));
            }

            // Normalize pixel value by dividing through number of samples
            pixel_color = pixel_color.div_scalar(@floatFromInt(self.samples_per_pixel));

            try writer.print("{}\n", .{pixel_color});
        }
    }
    std.debug.print("\rDone.                                                    \n", .{});
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

fn sample_camera_ray(self: Self, i: usize, j: usize) Ray {
    const pixel_center = self.pixel_00_loc
        .add(self.pixel_delta_u.mul_scalar(@floatFromInt(i)))
        .add(self.pixel_delta_v.mul_scalar(@floatFromInt(j)));
    const pixel_sample = pixel_center.add(self.pixel_sample_square());

    const ray_origin = self.center;
    const ray_direction = pixel_sample.sub(ray_origin);

    return Ray{
        .origin = ray_origin,
        .direction = ray_direction,
    };
}

fn pixel_sample_square(self: Self) Vec3 {
    const px = -0.5 * self.rand.float(f64);
    const py = -0.5 * self.rand.float(f64);

    return self.pixel_delta_u.mul_scalar(px)
        .add(self.pixel_delta_v.mul_scalar(py));
}
