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

#[test]
fn test_encode_empty() {
    let input: [u8; 0] = [];
    let result = encode(input);
    let expected: [u8; 0] = [];

    assert(result == expected);
}

#[test]
fn test_decode_empty() {
    let input: [u8; 0] = [];
    let expected: [u8; 0] = [];
    let result = decode(input);
    assert(result == expected);
}

#[test]

fn test_encode_padding() {
    // f
    let input: [u8; 1] = [102];
    let expected: [u8; 4] = [90, 103, 61, 61];
    let result = encode(input);

    assert(result == expected);

    // fo
    let input: [u8; 2] = [102, 111];
    let expected: [u8; 4] = [90, 109, 56, 61];
    let result = encode(input);

    assert(result == expected);

    // foo
    let input: [u8; 3] = [102, 111, 111];
    let expected: [u8; 4] = [90, 109, 57, 118];
    let result = encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_slash() {
    let input: [u8; 1] = [63];
    let expected:[u8; 4] = [76, 119, 61, 61];
    let result: [u8;4] = encode(input);

    assert(result == expected);
}

#[test]
fn test_decode_slash() {
    let input: [u8; 4] = [76, 119, 61, 61];
    let expected:[u8; 1] = [63];
    let result: [u8; 1] = decode(input);

    assert(result == expected);
}

#[test]
fn test_encode_max_byte() {
    let input: [u8; 1] = [255];
    let result: [u8; 4] = encode(input);
    let expected: [u8; 4] = [47, 119, 61, 61]; // "/w=="

    assert(result == expected);
}

#[test]
fn test_decode_max_byte() {
    let input: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    let result: [u8; 1] = decode(input);
    let expected: [u8; 1] = [255];

    assert(result == expected);
}

#[test]
fn test_encode_ascii() {
    // "Hello, World!"
    let input: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];

    // base64: SGVsbG8gV29ybGQh
    let result: [u8; 16] = encode(input);
    let expected: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];

    assert(result == expected);
}

#[test]
fn test_decode_ascii() {
    // "Hello, World!"
    let input: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];

    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let result: [u8; 12] = decode(input);
    let expected: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];

    assert(result == expected);
}

#[test]
fn test_encode_utf8() {
    // non-ascii utf-8: "Hello, World!" in Japanese: "こんにちは、世界！"
    let input: [u8; 27] = [
        227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 129, 175, 227, 128, 129, 228, 184, 150, 231, 149, 140, 239, 188, 129
    ];

    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let result: [u8; 36] = encode(input);
    let expected: [u8; 36] = [
        52, 52, 71, 84, 52, 52, 75, 84, 52, 52, 71, 114, 52, 52, 71, 104, 52, 52, 71, 118, 52, 52, 67, 66, 53, 76, 105, 87, 53, 53, 87, 77, 55, 55, 121, 66
    ];

    assert(result == expected);
}

#[test]
fn test_decode_utf8() {
    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let input: [u8; 36] = [
        52, 52, 71, 84, 52, 52, 75, 84, 52, 52, 71, 114, 52, 52, 71, 104, 52, 52, 71, 118, 52, 52, 67, 66, 53, 76, 105, 87, 53, 53, 87, 77, 55, 55, 121, 66
    ];

    // non-ascii utf-8: "Hello, World!" in Japanese: "こんにちは、世界！"
    let result: [u8; 27] = decode(input);
    let expected: [u8; 27] = [
        227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 129, 175, 227, 128, 129, 228, 184, 150, 231, 149, 140, 239, 188, 129
    ];

    assert(result == expected);
}
