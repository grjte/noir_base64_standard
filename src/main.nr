///! Encodings use the standard alphabet specified in RFC 4648 
///! (https://datatracker.ietf.org/doc/html/rfc4648#section-4)

global BASE64_PADDING_CHAR: u8 = 61;
// 240 bits fits 40 6-bit chunks and 30 8-bit chunks
// we pack 40 base64 values into a field element and convert into 30 bytes
global BASE64_PER_FIELD_ELEM: u32 = 40;
global BYTES_PER_FIELD_ELEM: u32 = 30;

struct Base64Encode {
    table: [u8; 64]
}

impl Base64Encode {
    fn new() -> Self {
        Base64Encode {
            table: [
                65, 66, 67, 68, 69, 70, 71, 72,// A, B, C, D, E, F, G, H
                73, 74, 75, 76, 77, 78, 79, 80,// I, J, K, L, M, N, O, P
                81, 82, 83, 84, 85, 86, 87, 88,// Q, R, S, T, U, V, W, X
                89, 90, 97, 98, 99, 100, 101, 102,// Y, Z, a, b, c, d, e, f
                103, 104, 105, 106, 107, 108, 109, 110,// g, h, i, j, k, l, m, n
                111, 112, 113, 114, 115, 116, 117, 118,// o, p, q, r, s, t, u, v
                119, 120, 121, 122, 48, 49, 50, 51,// w, x, y, z, 0, 1, 2, 3
                52, 53, 54, 55, 56, 57, 43, 47// 4, 5, 6, 7, 8, 9, +, /
            ]
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }

    fn encode_byte1(self, byte_1: u8) -> u8 {
        // TODO: replace bitwise ops with arithmetic
        let base64_idx= byte_1 >> 2;
        self.get(base64_idx as Field)
    }

    fn encode_byte2(self, byte_1: u8, byte_2: u8) -> u8 {
        // byte_1 & 0b0000_0011
        // TODO: replace bitwise ops with arithmetic
        let base64_idx = (byte_1 & 3) << 4 | byte_2 >> 4;
        self.get(base64_idx as Field)
    }

    fn encode_byte3(self, byte_2: u8, byte_3: u8) -> u8 {
        // byte_2 & 0b0000_1111
        // TODO: replace bitwise ops with arithmetic
        let base64_idx = (byte_2 & 15) << 2 | byte_3 >> 6;
        self.get(base64_idx as Field)
    }

    fn encode_byte4(self, byte_3: u8) -> u8 {
        // byte_3 & 0b0011_1111
        // TODO: replace bitwise ops with arithmetic
        let base64_idx = byte_3 & 63;
        self.get(base64_idx as Field)
    }
}

struct Base64Decode {
    table: [u8; 123]
}

impl Base64Decode {
    fn new() -> Self {
        Base64Decode {
            table: [
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 0-19 (no mapping)
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 20-39 (no mapping)
                0, 0, 0,// 40-42 (no mapping)
                62,// 43 (+)
                0, 0, 0,// 44-46 (no mapping)
                63,// 47 (/)
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61,// 48-57 (0-9)
                0, 0, 0, 0, 0, 0, 0,// 58-64 (no mapping)
                0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                23, 24, 25,// 65-90 (A-Z)
                0, 0, 0, 0, 0, 0,// 91-96 (no mapping)
                26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
                47, 48, 49, 50, 51// 97-122 (a-z)
            ]
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }
}

/// @brief Encode an array of arbitrary bytes as base64 values; return a base64-encoded byte array
pub fn encode<let InputBytes: u32, let OutputBytes: u32>(input_bytes: [u8; InputBytes]) -> [u8; OutputBytes] {
    let mut Base64Encoder = Base64Encode::new();

    // take the input bytes in chunks of 3 (24 bits)
    let num_chunks = (InputBytes / 3);
    // define the encoded size
    let mut result: [u8; OutputBytes] = [0; OutputBytes];

    // TODO: switch to this method
    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // pack 30 bytes into a field element
    // convert the field element to 40 6-bit chunks

    for i in 0..num_chunks {
        // split the 24 bits into groups of 6-bits
        let byte_i = 3 * i;
        let byte_1 = input_bytes[byte_i];
        let byte_2 = input_bytes[byte_i + 1];
        let byte_3 = input_bytes[byte_i + 2];
        let base64_i = 4 * i;

        // convert each 6-bit group to its corresponding base64 character
        result[base64_i] = Base64Encoder.encode_byte1(byte_1);
        result[base64_i + 1] = Base64Encoder.encode_byte2(byte_1, byte_2);
        result[base64_i + 2] = Base64Encoder.encode_byte3(byte_2, byte_3);
        result[base64_i + 3] = Base64Encoder.encode_byte4(byte_3);
    }

    // if the last group is less than 3 bytes, add padding
    let final_chunk = InputBytes % 3;
    if (final_chunk == 1) {
        let byte_i = 3 * num_chunks;
        let base64_i = 4 * num_chunks;
        // 2 base64 characters
        let byte_1 = input_bytes[byte_i];
        result[base64_i] = Base64Encoder.encode_byte1(byte_1);
        result[base64_i + 1] = Base64Encoder.encode_byte2(byte_1, 0);
        // 2 padding characters
        result[base64_i + 2] = BASE64_PADDING_CHAR;
        result[base64_i + 3] = BASE64_PADDING_CHAR;
    } else if (final_chunk == 2) {
        let byte_i = 3 * num_chunks;
        let base64_i = 4 * num_chunks;
        // 3 base64 characters
        let byte_1 = input_bytes[byte_i];
        let byte_2 = input_bytes[byte_i + 1];
        result[base64_i] = Base64Encoder.encode_byte1(byte_1);
        result[base64_i + 1] = Base64Encoder.encode_byte2(byte_1, byte_2);
        result[base64_i + 2] = Base64Encoder.encode_byte3(byte_2, 0);
        // 1 padding character
        result[base64_i + 3] = BASE64_PADDING_CHAR;
    }

    result
}

/// @brief Decode a byte array representing base64 values back to raw bytes
pub fn decode<let InputBytes: u32, let OutputBytes: u32>(input_bytes: [u8; InputBytes]) -> [u8; OutputBytes] {
    // if the input length is not a multiple of 4, then it's not a valid base64 encoding
    assert(InputBytes % 4 == 0);

    let mut result: [u8; OutputBytes] = [0; OutputBytes];
    if (InputBytes == 0) {
        // TODO: no early return; replace this
        result
    }

    let mut Base64Decoder = Base64Decode::new();
    let num_chunks = (InputBytes / BASE64_PER_FIELD_ELEM) + (InputBytes % BASE64_PER_FIELD_ELEM != 0) as u32;
    let final_chunk = num_chunks - 1;

    for i in 0..final_chunk {
        // pack the base64 values into the Field element
        let mut slice: Field = 0;
        for j in 0..BASE64_PER_FIELD_ELEM {
            // shift by 6 bits
            slice *= 64;
            // get the 6-bit value for this base64 element
            let base64_6bit = Base64Decoder.get(input_bytes[i * BASE64_PER_FIELD_ELEM + j] as Field);
            // add the 6-bit value to the Field element
            slice += base64_6bit as Field;
        }
        // extract the bytes from the Field element
        let slice_bytes: [u8; BYTES_PER_FIELD_ELEM] = slice.to_be_bytes();
        for j in 0..BYTES_PER_FIELD_ELEM {
            result[i*BYTES_PER_FIELD_ELEM + j] = slice_bytes[j];
        }
    }

    // process the final chunk, which may contain padding
    let mut num_final_base64 = InputBytes - (final_chunk * BASE64_PER_FIELD_ELEM);
    let mut num_final_bytes = num_final_base64 / 4 * 3;
    // remove the padding, if there is any
    if (input_bytes[InputBytes - 1] == BASE64_PADDING_CHAR) {
        num_final_base64 -= 1;
        num_final_bytes -= 1;
    }
    if (input_bytes[InputBytes - 2] == BASE64_PADDING_CHAR) {
        // if a non-padding byte follows a padding byte, the base64 is invalid
        assert(input_bytes[InputBytes - 1] == BASE64_PADDING_CHAR);
        num_final_base64 -= 1;
        num_final_bytes -= 1;
    }

    // pack the base64 values into the Field element
    let mut slice: Field = 0;
    for j in 0..num_final_base64 {
        // shift by 6 bits
        slice *= 64;
        // get the 6-bit value for this base64 element
        let base64_6bit = Base64Decoder.get(input_bytes[final_chunk * BASE64_PER_FIELD_ELEM + j] as Field);
        // add the 6-bit value to the Field element
        slice += base64_6bit as Field;
    }

    for _ in num_final_base64..BASE64_PER_FIELD_ELEM {
        slice *= 64;
    }
    // extract the bytes from the Field element
    let slice_bytes: [u8; BYTES_PER_FIELD_ELEM] = slice.to_be_bytes();
    for j in 0..num_final_bytes {
        result[final_chunk * BYTES_PER_FIELD_ELEM + j] = slice_bytes[j];
    }

    result
}

fn main() {
    // let message = "Hello World!";
    // let message_bytes: [u8; 12] = message.as_bytes();
    // println(message_bytes);
    // let result: [u8; 16] = encode(message_bytes);

    // let input: [u8; 1] = [47];
    // let result: [u8;4] = encode(input);

    // f
    let input: [u8; 4] = [90, 103, 61, 61];
    let expected: [u8; 1] = [102];
    let result: [u8; 1] = decode(input);

    // fo
    let input: [u8; 4] = [90, 109, 56, 61];
    let expected: [u8; 2] = [102, 111];
    let result: [u8; 2] = decode(input);
    // // foo
    // let input: [u8; 4] = [90, 109, 57, 118];
    // let expected: [u8; 3] = [102, 111, 111];
    // let result = decode(input);
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
fn test_decode_padding() {
    // f
    let input: [u8; 4] = [90, 103, 61, 61];
    let expected: [u8; 1] = [102];
    let result = decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 4] = [90, 109, 56, 61];
    let expected: [u8; 2] = [102, 111];
    let result = decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = decode(input);

    assert(result == expected);
}

#[test]
fn test_encode_slash() {
    let input: [u8; 1] = [47];
    let expected:[u8; 4] = [76, 119, 61, 61];
    let result: [u8;4] = encode(input);

    assert(result == expected);
}

#[test]
fn test_decode_slash() {
    let input: [u8; 4] = [76, 119, 61, 61];
    let expected:[u8; 1] = [47];
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
    // "Hello World!"
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
