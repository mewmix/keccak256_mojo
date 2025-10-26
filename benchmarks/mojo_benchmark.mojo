from keccak.keccak256 import keccak256_bytes

alias NUM_MESSAGES = 512
alias ROUNDS = 200
alias BASE_LENGTH = 32
alias MAX_LENGTH = 512
alias LENGTH_STRIDE = 31


fn message_length(index: Int) -> Int:
    var span = MAX_LENGTH - BASE_LENGTH + 1
    return BASE_LENGTH + ((index * LENGTH_STRIDE) % span)


fn generate_message(index: Int) -> List[Int]:
    var length = message_length(index)
    var data = [0] * length
    for offset in range(length):
        data[offset] = (index + offset) % 256
    return data.copy()


def main():
    var total = 0
    for _ in range(ROUNDS):
        for idx in range(NUM_MESSAGES):
            var message = generate_message(idx)
            var digest = keccak256_bytes(message, len(message))
            total += digest[0]
    if total == -1:
        print("unreachable")
