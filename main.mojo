from keccak.keccak256 import keccak256_string, to_hex32


def main():
    var d = keccak256_string("abc")
    print(to_hex32(d))

