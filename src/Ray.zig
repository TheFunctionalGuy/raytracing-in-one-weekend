const Vec3 = @import("Vec3.zig");

const Point3 = Vec3;

origin: Point3,
direction: Vec3,

const Self = @This();

pub fn new(origin: Point3, direction: Vec3) Self {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: Self, t: f64) Point3 {
    return self.origin.add(self.direction.mul_scalar(t));
}
