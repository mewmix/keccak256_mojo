//! Minimal Keccak-256 helper used by benchmark smoke tests.

use tiny_keccak::{Hasher, Keccak};

/// Compute the Keccak-256 digest of the provided message.
pub fn keccak256(message: &[u8]) -> [u8; 32] {
    let mut hasher = Keccak::v256();
    hasher.update(message);
    let mut output = [0u8; 32];
    hasher.finalize(&mut output);
    output
}

/// Render a digest as a lowercase hexadecimal string.
pub fn to_hex_string(bytes: &[u8]) -> String {
    hex::encode(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Check the canonical "abc" test vector.
    #[test]
    fn keccak256_abc_matches_expected() {
        let digest = keccak256(b"abc");
        assert_eq!(
            to_hex_string(&digest),
            "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"
        );
    }

    /// Ensure the helper handles an empty message.
    #[test]
    fn keccak256_empty_matches_expected() {
        let digest = keccak256(b"");
        assert_eq!(
            to_hex_string(&digest),
            "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
        );
    }
}
