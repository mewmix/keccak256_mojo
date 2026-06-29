const std = @import("std");
const Keccak256 = std.crypto.hash.sha3.Keccak256;

const NUM_HASHES: usize = 200_000_000;
const PREFIX = "someFunc(uint256,address)";
const NUM_THREADS = 8;

fn worker(start_nonce: u64, end_nonce: u64, found_count: *std.atomic.Value(u32)) void {
    var base_hasher = Keccak256.init(.{});
    base_hasher.update(PREFIX);

    var i: u64 = start_nonce;
    while (i < end_nonce) : (i += 1) {
        var hasher = base_hasher;
        var nonce_bytes: [8]u8 = undefined;
        std.mem.writeInt(u64, &nonce_bytes, i, .big);
        hasher.update(&nonce_bytes);
        
        var out: [32]u8 = undefined;
        hasher.final(&out);
        
        if (out[0] == 0xde and out[1] == 0xad and out[2] == 0xbe and out[3] == 0xef) {
            _ = found_count.fetchAdd(1, .monotonic);
        }
    }
}

pub fn main() !void {
    var found_count = std.atomic.Value(u32).init(0);
    const chunk_size = NUM_HASHES / NUM_THREADS;
    
    var threads: [NUM_THREADS]std.Thread = undefined;
    for (&threads, 0..) |*thread, i| {
        const start_nonce = @as(u64, i) * chunk_size;
        const end_nonce = @as(u64, i + 1) * chunk_size;
        thread.* = try std.Thread.spawn(.{}, worker, .{ start_nonce, end_nonce, &found_count });
    }

    for (threads) |thread| {
        thread.join();
    }
}
