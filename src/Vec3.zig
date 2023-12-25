const std = @import("std");

const Interval = @import("Interval.zig");

underlying_vector: @Vector(3, f64) = .{ 0.0, 0.0, 0.0 },

const Self = @This();

// Init
pub fn new(e_1: f64, e_2: f64, e_3: f64) Self {
    return .{ .underlying_vector = .{ e_1, e_2, e_3 } };
}

pub fn default() Self {
    return .{};
}

// Getters
pub fn x(self: Self) f64 {
    return self.underlying_vector[0];
}

pub fn y(self: Self) f64 {
    return self.underlying_vector[1];
}

pub fn z(self: Self) f64 {
    return self.underlying_vector[2];
}

// Utility
pub fn add(self: Self, other: Self) Self {
    return .{ .underlying_vector = self.underlying_vector + other.underlying_vector };
}

pub fn sub(self: Self, other: Self) Self {
    return .{ .underlying_vector = self.underlying_vector - other.underlying_vector };
}

pub fn invert(self: Self) Self {
    return .{ .underlying_vector = -self.underlying_vector };
}

pub fn mul_scalar(self: Self, scalar: f64) Self {
    return .{
        .underlying_vector = .{
            self.underlying_vector[0] * scalar,
            self.underlying_vector[1] * scalar,
            self.underlying_vector[2] * scalar,
        },
    };
}

pub fn div_scalar(self: Self, scalar: f64) Self {
    const factor = 1 / scalar;

    return self.mul_scalar(factor);
}

pub fn mul_dot(self: Self, other: Self) f64 {
    return @reduce(.Add, self.underlying_vector * other.underlying_vector);
}

pub fn length(self: Self) f64 {
    return @sqrt(self.length_squared());
}

pub fn length_squared(self: Self) f64 {
    return @reduce(.Add, self.underlying_vector * self.underlying_vector);
}

pub fn unit_vector(self: Self) Self {
    return self.div_scalar(self.length());
}

// Printing
pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    if (fmt.len != 0) {
        std.fmt.invalidFmtError(fmt, self);
    }
    _ = options;

    const intensity = Interval.new(0.000, 0.999);

    const e_1: usize = @intFromFloat(256 * intensity.clamp(self.x()));
    const e_2: usize = @intFromFloat(256 * intensity.clamp(self.y()));
    const e_3: usize = @intFromFloat(256 * intensity.clamp(self.z()));

    try writer.print("{} {} {}", .{ e_1, e_2, e_3 });
}
