const HitRecord = @import("collision.zig").HitRecord;
const Interval = @import("Interval.zig");
const Point3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");

center: Point3,
radius: f64,

const Self = @This();

pub fn new(center: Point3, radius: f64) Self {
    return .{
        .center = center,
        .radius = radius,
    };
}

pub fn hit(self: Self, ray: Ray, ray_t: Interval, record: *HitRecord) bool {
    const oc: Point3 = ray.origin.sub(self.center);

    const a: f64 = ray.direction.length_squared();
    const half_b: f64 = oc.mul_dot(ray.direction);
    const c: f64 = oc.length_squared() - self.radius * self.radius;

    const discriminant: f64 = half_b * half_b - a * c;

    if (discriminant < 0) {
        return false;
    }

    const sqrt_discriminant: f64 = @sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range
    var root: f64 = (-half_b - sqrt_discriminant) / a;

    if (!ray_t.surrounds(root)) {
        root = (-half_b + sqrt_discriminant) / a;

        if (!ray_t.surrounds(root)) {
            return false;
        }
    }

    record.t = root;
    record.point = ray.at(record.t);
    const outward_normal = record.point.sub(self.center).div_scalar(self.radius);
    record.set_face_normal(ray, outward_normal);

    return true;
}
