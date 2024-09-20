///! Encodings use the standard alphabet specified in RFC 4648 
///! (https://datatracker.ietf.org/doc/html/rfc4648#section-4)

/// @brief Encode an array of arbitrary bytes as base64 values
pub fn encode<let InputBytes: u32, let OutputBytes: u32>(input: [u8; InputBytes]) -> [u8; OutputBytes] {
    // define the encoded size
    let mut result: [u8; OutputBytes] = [0; OutputBytes];

    // encode with padding
    result
}

/// @brief Decode a byte array representing base64 values back to raw bytes
pub fn decode<let InputBytes: u32, let OutputBytes: u32>(input: [u8; InputBytes]) -> [u8; OutputBytes] {
    // define the decoded size
    let mut result: [u8; OutputBytes] = [0; OutputBytes];

    // decode with padding
    result
}

fn main(x: Field, y: pub Field) {
    assert(x != y);
}
