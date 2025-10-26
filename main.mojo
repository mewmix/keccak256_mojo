from keccak.keccak256 import keccak256_string, to_hex32

alias STR = "abc"

def main():
    var d = keccak256_string(STR)
    print(to_hex32(d))

