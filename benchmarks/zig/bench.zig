const std = @import("std");
const Keccak256 = std.crypto.hash.sha3.Keccak256;

const NUM_MESSAGES: usize = 512;
const ROUNDS: usize = 200;
const BASE_LENGTH: usize = 32;
const MAX_LENGTH: usize = 512;
const LENGTH_STRIDE: usize = 31;
const WARMUP_ROUNDS: usize = 3;

fn messageLength(index: usize) usize {
    const span = MAX_LENGTH - BASE_LENGTH + 1;
    return BASE_LENGTH + ((index * LENGTH_STRIDE) % span);
}

fn generateMessage(index: usize, buffer: []u8) usize {
    const length = messageLength(index);
    for (0..length) |offset| {
        buffer[offset] = @as(u8, @intCast((index + offset) % 256));
    }
    return length;
}

fn warmUp() void {
    var message: [MAX_LENGTH]u8 = undefined;
    var digest: [32]u8 = undefined;
    for (0..WARMUP_ROUNDS) |_| {
        for (0..NUM_MESSAGES) |idx| {
            const length = generateMessage(idx, &message);
            Keccak256.hash(message[0..length], &digest, .{});
        }
    }
}

pub fn main() !void {
    const label: []const u8 = "zig (stdlib)";
    warmUp();

    var checksum: u32 = 0;
    var message: [MAX_LENGTH]u8 = undefined;
    var digest: [32]u8 = undefined;

    for (0..ROUNDS) |_| {
        for (0..NUM_MESSAGES) |idx| {
            const length = generateMessage(idx, &message);
            Keccak256.hash(message[0..length], &digest, .{});
            checksum ^= digest[0];
        }
    }

    std.debug.print("implementation | seconds | hashes/s | checksum\n", .{});
    std.debug.print("-------------- | ------- | -------- | --------\n", .{});
    std.debug.print("{s} | 0.0 | 0.0 | {d}\n", .{ label, checksum });
}
