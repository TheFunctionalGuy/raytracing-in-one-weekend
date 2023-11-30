const std = @import("std");
const infinity = std.math.inf(f64);

min: f64,
max: f64,

const Self = @This();

pub fn new(min: f64, max: f64) Self {
    return .{
        .min = min,
        .max = max,
    };
}

pub fn default() Self {
    return empty();
}

pub fn empty() Self {
    return .{
        .min = infinity,
        .max = -infinity,
    };
}

pub fn universe() Self {
    return .{
        .min = -infinity,
        .max = infinity,
    };
}

pub fn contains(self: Self, x: f64) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Self, x: f64) bool {
    return self.min < x and x < self.max;
}
