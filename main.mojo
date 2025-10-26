from keccak.keccak256 import keccak256_string

fn to_hex32(d: List[Int]) -> String:
    var lut = "0123456789abcdef"
    var out = ""
    for v in d:
        var b = v & 0xFF
        out += lut[(b >> 4) & 0xF]
        out += lut[b & 0xF]
    return out

# ---- EDIT THIS ONLY ----
alias STR = "abc"
# ------------------------

def main():
    var d = keccak256_string(STR)
    print(to_hex32(d))

