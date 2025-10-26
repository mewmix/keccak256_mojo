use std::env;
use std::time::Instant;

use keccak256_rust_baseline::keccak256;

const NUM_MESSAGES: usize = 512;
const ROUNDS: usize = 200;
const BASE_LENGTH: usize = 32;
const MAX_LENGTH: usize = 512;
const LENGTH_STRIDE: usize = 31;
const WARMUP_ROUNDS: usize = 3;

fn message_length(index: usize) -> usize {
    let span = MAX_LENGTH - BASE_LENGTH + 1;
    BASE_LENGTH + (index * LENGTH_STRIDE) % span
}

fn generate_message(index: usize) -> Vec<u8> {
    let length = message_length(index);
    let mut message = Vec::with_capacity(length);
    for offset in 0..length {
        message.push(((index + offset) % 256) as u8);
    }
    message
}

fn warm_up() {
    for _ in 0..WARMUP_ROUNDS {
        for idx in 0..NUM_MESSAGES {
            let message = generate_message(idx);
            let digest = keccak256(&message);
            std::hint::black_box(digest[0]);
        }
    }
}

struct BenchmarkResult {
    seconds: f64,
    checksum: u32,
}

fn run_benchmark() -> BenchmarkResult {
    warm_up();
    let mut checksum: u32 = 0;
    let start = Instant::now();

    for _ in 0..ROUNDS {
        for idx in 0..NUM_MESSAGES {
            let message = generate_message(idx);
            let digest = keccak256(&message);
            checksum ^= digest[0] as u32;
        }
    }

    let elapsed = start.elapsed().as_secs_f64();
    BenchmarkResult {
        seconds: elapsed,
        checksum,
    }
}

fn print_table(label: &str, seconds: f64, hashes_per_second: f64, checksum: u32) {
    println!("implementation | seconds | hashes/s | checksum");
    println!("-------------- | ------- | -------- | --------");
    println!("{} | {:.9} | {:.2} | {}", label, seconds, hashes_per_second, checksum);
}

fn print_json(label: &str, seconds: f64, hashes_per_second: f64, checksum: u32) {
    println!(
        "{{\"implementation\": \"{}\", \"seconds\": {:.12}, \"hashes_per_second\": {:.2}, \"checksum\": {}}}",
        label, seconds, hashes_per_second, checksum
    );
}

fn main() {
    let mut label = String::from("rust (tiny-keccak)");
    let mut emit_json = false;

    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--json" => emit_json = true,
            "--label" => {
                if let Some(value) = args.next() {
                    label = value;
                }
            }
            _ => {}
        }
    }

    let result = run_benchmark();
    let total_hashes = (NUM_MESSAGES * ROUNDS) as f64;
    let throughput = if result.seconds > 0.0 {
        total_hashes / result.seconds
    } else {
        0.0
    };

    if emit_json {
        print_json(&label, result.seconds, throughput, result.checksum);
    } else {
        print_table(&label, result.seconds, throughput, result.checksum);
    }
}
