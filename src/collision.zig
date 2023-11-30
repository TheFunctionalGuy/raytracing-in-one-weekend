const std = @import("std");

const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const Vec3 = @import("Vec3.zig");

const Allocator = std.mem.Allocator;
const HittableList = std.ArrayList(Hittable);
const Point3 = Vec3;

pub const HitRecord = struct {
    // For easy uninitialized creation
    point: Point3 = undefined,
    normal: Vec3 = undefined,
    t: f64 = undefined,
    front_face: bool = undefined,

    pub fn set_face_normal(self: *HitRecord, ray: Ray, outward_normal: Vec3) void {
        self.front_face = ray.direction.mul_dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.invert();
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,
    hit_list: HitList,

    pub fn hit(self: Hittable, ray: Ray, ray_t: Interval, record: *HitRecord) bool {
        switch (self) {
            inline else => |case| return case.hit(ray, ray_t, record),
        }
    }
};

pub const HitList = struct {
    allocator: Allocator,
    objects: HittableList,

    pub fn init(allocator: Allocator) HitList {
        const objects = HittableList.init(allocator);

        return .{
            .allocator = allocator,
            .objects = objects,
        };
    }

    pub fn deinit(self: *HitList) void {
        self.objects.deinit();
    }

    pub fn clear(self: *HitList) void {
        self.objects.clearRetainingCapacity();
    }

    pub fn add(self: *HitList, object: Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: HitList, ray: Ray, ray_t: Interval, record: *HitRecord) bool {
        var temp_record = HitRecord{};
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(ray, Interval.new(ray_t.min, closest_so_far), &temp_record)) {
                hit_anything = true;
                closest_so_far = temp_record.t;
                record.* = temp_record;
            }
        }

        return hit_anything;
    }
};
