import time
from algorithm import parallelize
from memory import UnsafePointer
from keccak.keccak256 import keccak_f1600
from collections.inline_array import InlineArray
from sys import num_logical_cores

alias TARGET_PREFIX = "someFunc(uint256,address)"
alias PREFIX_LEN = 25
alias NUM_HASHES = 200_000_000

fn get_base_state() raises -> InlineArray[UInt64, 25]:
    var state = InlineArray[UInt64, 25](fill=0)
    var state_bytes = UnsafePointer(to=state[0]).bitcast[UInt8]()
    
    var prefix = TARGET_PREFIX
    for i in range(PREFIX_LEN):
        state_bytes.offset(i)[] = UInt8(ord(prefix[i]))
        
    state_bytes.offset(33)[] = UInt8(0x01)
    state_bytes.offset(135)[] = UInt8(0x80)
    
    return state

fn run_bruteforce() raises -> Float64:
    var base_state = get_base_state()
    var base_ptr = UnsafePointer(to=base_state[0])
    
    var start = time.perf_counter()
    var cores = num_logical_cores()
    var chunk_size = NUM_HASHES // cores
    
    @parameter
    fn worker(core_idx: Int):
        var local_state = InlineArray[UInt64, 25](fill=0)
        var local_ptr = UnsafePointer(to=local_state[0])
        var start_nonce = UInt64(core_idx * chunk_size)
        var end_nonce = UInt64((core_idx + 1) * chunk_size)
        
        var base_v1 = base_ptr.load[width=16]()
        var base_v2 = base_ptr.offset(16).load[width=8]()
        var base_last = base_ptr.offset(24)[]
        
        for nonce in range(start_nonce, end_nonce):
            local_ptr.store[width=16](0, base_v1)
            local_ptr.offset(16).store[width=8](0, base_v2)
            local_ptr.offset(24)[] = base_last
            
            var shifted_nonce_word3 = (nonce << 8)
            var shifted_nonce_word4 = (nonce >> 56)
            
            local_ptr.offset(3)[] ^= shifted_nonce_word3
            local_ptr.offset(4)[] ^= shifted_nonce_word4
            
            keccak_f1600(local_ptr)
            
            if local_ptr[] == 0xdeadbeef:
                print("Found!")

    parallelize[worker](cores)
    
    var elapsed = time.perf_counter() - start
    return elapsed

fn main() raises:
    var elapsed = run_bruteforce()
    var rate = Float64(NUM_HASHES) / elapsed
    print("[")
    print("  {")
    print("    \"implementation\": \"mojo (bruteforce)\",")
    print("    \"seconds\": " + String(elapsed) + ",")
    print("    \"hashes_per_second\": " + String(rate))
    print("  }")
    print("]")
