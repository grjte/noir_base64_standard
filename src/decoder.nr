use super::defaults::{BASE64_PADDING_CHAR, BASE64_PER_FIELD_ELEM, BYTES_PER_FIELD_ELEM};

global STANDARD = Base64Decode::new(true);
global URL_SAFE = Base64Decode::base64url(true);
global STANDARD_NO_PAD = Base64Decode::new(false);
global URL_SAFE_NO_PAD = Base64Decode::base64url(false);

global INVALID_VALUE: u8 = 255;

struct Base64Decode {
    table: [u8; 123],
    pad: bool
}

impl Base64Decode {
    // Creates a new decoder that uses the standard alphabet, base64, specified in RFC 4648
    // https://datatracker.ietf.org/doc/html/rfc4648#section-5
    fn new(pad: bool) -> Self {
        Base64Decode {
            // To decode an array of Base64 values that have been encoded as bytes using UTF-8
            // encodings of the Base64 alphabet, UTF-8 must be mapped back to the corresponding Base64 6-bit values.
            table: [
                // 0-42 (no mapping)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,
                62,// 43 (+)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,// 44-46 (no mapping)
                63,// 47 (/)
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61,// 48-57 (0-9)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,// 58-64 (no mapping)
                0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                23, 24, 25,// 65-90 (A-Z)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,// 91-96 (no mapping)
                26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
                47, 48, 49, 50, 51// 97-122 (a-z)
            ],
            pad
        }
    }

    // Creates a new decoder that uses the URL and Filename Safe Alphabet specified in RFC 4648
    // https://datatracker.ietf.org/doc/html/rfc4648#section-5
    fn base64url(pad: bool) -> Self {
        Base64Decode {
            table: [
                // 0-44 (no mapping)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,
                62,// 45 (-)
                INVALID_VALUE, INVALID_VALUE,// 46-47 (no mapping)
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61,// 48-57 (0-9)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,// 58-64 (no mapping)
                0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                23, 24, 25,// 65-90 (A-Z)
                INVALID_VALUE, INVALID_VALUE, INVALID_VALUE, INVALID_VALUE,// 91-94 (no mapping)
                63,// 95 (_)
                0,// 96 (no mapping)
                26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
                47, 48, 49, 50, 51// 97-122 (a-z)
            ],
            pad
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }

    /// @brief Decode a byte array representing base64 values back to raw bytes
    pub fn decode<let InputBytes: u32, let OutputBytes: u32>(
        self,
        input_bytes: [u8; InputBytes]
    ) -> [u8; OutputBytes] {
        if self.pad {
            // if the input length is not a multiple of 4, then it's not a valid base64 encoding
            assert(InputBytes % 4 == 0);
        }

        // TODO: once arithmetic ops on generics are supported, derive OutputBytes from InputBytes so it
        // is correctly constrained.
        let mut result: [u8; OutputBytes] = [0; OutputBytes];

        // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
        // pack 30 bytes into a field element, then convert the field element to 40 6-bit chunks
        let num_chunks = (InputBytes / BASE64_PER_FIELD_ELEM) + (InputBytes % BASE64_PER_FIELD_ELEM != 0) as u32;

        if num_chunks > 0 {
            let final_chunk = num_chunks - 1;
            let mut slice: Field = 0;

            for i in 0..final_chunk {
                // pack the base64 values into the Field element
                for j in 0..BASE64_PER_FIELD_ELEM {
                    // shift by 6 bits
                    slice *= 64;
                    // get the 6-bit value corresponding to this base64 element
                    let offset = i * BASE64_PER_FIELD_ELEM + j;
                    let input_byte = input_bytes[offset];
                    let base64_6bit = self.get(input_byte as Field);
                    assert(
                        base64_6bit != INVALID_VALUE, f"DecodeError: invalid symbol {input_byte}, offset {offset}."
                    );
                    // add the 6-bit value to the Field element
                    slice += base64_6bit as Field;
                }
                // extract the bytes from the Field element
                let slice_bytes: [u8; BYTES_PER_FIELD_ELEM] = slice.to_be_bytes();
                for j in 0..BYTES_PER_FIELD_ELEM {
                    result[i*BYTES_PER_FIELD_ELEM + j] = slice_bytes[j];
                }
                // reset the Field element
                slice = 0;
            }

            // process the final chunk, which may contain padding
            let base64_offset = final_chunk * BASE64_PER_FIELD_ELEM;
            let byte_offset = final_chunk * BYTES_PER_FIELD_ELEM;
            let mut num_final_base64 = InputBytes - base64_offset;
            let num_final_bytes = OutputBytes - byte_offset;

            if self.pad {
                // enforce Base64 padding is valid, then strip the padding
                if (input_bytes[InputBytes - 2] == BASE64_PADDING_CHAR) {
                    // if a non-padding byte follows a padding byte, the base64 is invalid
                    assert(input_bytes[InputBytes - 1] == BASE64_PADDING_CHAR);
                    num_final_base64 -= 2;
                } else if (input_bytes[InputBytes - 1] == BASE64_PADDING_CHAR) {
                    num_final_base64 -= 1;
                }
            }

            // pack the base64 values into the Field element
            for j in 0..num_final_base64 {
                slice *= 64;
                let offset = base64_offset + j;
                let input_byte = input_bytes[offset];
                let base64_6bit = self.get(input_byte as Field);
                assert(
                    base64_6bit != INVALID_VALUE, f"DecodeError: invalid symbol {input_byte}, offset {offset}."
                );
                slice += base64_6bit as Field;
            }
            for _ in num_final_base64..BASE64_PER_FIELD_ELEM {
                slice *= 64;
            }

            // extract the bytes from the Field element
            let slice_bytes: [u8; BYTES_PER_FIELD_ELEM] = slice.to_be_bytes();
            for j in 0..num_final_bytes {
                result[byte_offset + j] = slice_bytes[j];
            }
        }

        result
    }
}

// === TESTS ======================================================================================

#[test]
fn test_decode_empty() {
    let input: [u8; 0] = [];
    let expected: [u8; 0] = [];
    let result = STANDARD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_padding() {
    // f
    let input: [u8; 4] = [90, 103, 61, 61];
    let expected: [u8; 1] = [102];
    let result = STANDARD.decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 4] = [90, 109, 56, 61];
    let expected: [u8; 2] = [102, 111];
    let result = STANDARD.decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = STANDARD.decode(input);

    assert(result == expected);
}

#[test]
fn test_decode_max_byte() {
    let expected: [u8; 1] = [255];

    let input: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    let result: [u8; 1] = STANDARD.decode(input);
    assert(result == expected);

    let input: [u8; 2] = [47, 119]; // "/w"
    let result: [u8; 1] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);

    let input: [u8; 4] = [95, 119, 61, 61]; // "_w=="
    let result: [u8; 1] = URL_SAFE.decode(input);
    assert(result == expected);

    let input: [u8; 2] = [95, 119]; // "_w"
    let result: [u8; 1] = URL_SAFE_NO_PAD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_ascii() {
    // base64: SGVsbG8gV29ybGQh
    let input: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];
    // "Hello World!"
    let expected: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];

    // all configurations should decode the same way
    let result: [u8; 12] = STANDARD.decode(input);
    assert(result == expected);
    let result: [u8; 12] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 12] = URL_SAFE.decode(input);
    assert(result == expected);
    let result: [u8; 12] = URL_SAFE_NO_PAD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_utf8() {
    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let input: [u8; 36] = [
        52, 52, 71, 84, 52, 52, 75, 84, 52, 52, 71, 114, 52, 52, 71, 104, 52, 52, 71, 118, 52, 52, 67, 66, 53, 76, 105, 87, 53, 53, 87, 77, 55, 55, 121, 66
    ];
    // non-ascii utf-8: "Hello, World!" in Japanese: "こんにちは、世界！"
    let expected: [u8; 27] = [
        227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 129, 175, 227, 128, 129, 228, 184, 150, 231, 149, 140, 239, 188, 129
    ];

    let result: [u8; 27] = STANDARD.decode(input);
    assert(result == expected);
    let result: [u8; 27] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 27] = URL_SAFE.decode(input);
    assert(result == expected);
    let result: [u8; 27] = URL_SAFE_NO_PAD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_44ascii() {
    let input: [u8; 60] = [
        82, 51, 104, 78, 98, 71, 100, 51, 84, 71, 108, 53, 99, 71, 53, 87, 99, 107, 85, 121, 81,
        122, 66, 84, 90, 106, 82, 53, 101, 109, 104, 106, 86, 49, 82, 114, 81, 87, 104, 84, 87,
        106, 85, 114, 86, 48, 86, 83, 97, 69, 116, 111, 87, 72, 82, 115, 86, 84, 48, 61
    ];

    let result = STANDARD.decode(input);
    // Ascii string: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    let expected: [u8; 44] = [
        71, 120, 77, 108, 103, 119, 76, 105, 121, 112, 110, 86, 114, 69, 50, 67, 48, 83, 102, 52,
        121, 122, 104, 99, 87, 84, 107, 65, 104, 83, 90, 53, 43, 87, 69, 82, 104, 75, 104, 88, 116,
        108, 85, 61
    ];

    assert(result == expected);
}

#[test]
fn test_decode_paragraph() {
    let input:[u8; 816] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73, 71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73, 72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 119, 103, 100, 50, 104, 112, 98, 71, 85, 103, 78, 68, 73, 103, 99, 109, 70, 50, 90, 87, 53, 122, 73, 72, 66, 108, 99, 109, 78, 111, 73, 71, 70, 48, 98, 51, 65, 103, 89, 83, 66, 121, 100, 88, 78, 48, 101, 83, 66, 116, 89, 87, 108, 115, 89, 109, 57, 52, 76, 105, 66, 97, 89, 87, 53, 53, 73, 72, 70, 49, 97, 87, 120, 48, 90, 88, 74, 122, 73, 71, 90, 104, 89, 110, 74, 112, 89, 50, 70, 48, 90, 83, 65, 53, 73, 71, 78, 118, 101, 110, 107, 103, 89, 109, 120, 104, 98, 109, 116, 108, 100, 72, 77, 115, 73, 71, 70, 122, 73, 68, 77, 103, 97, 109, 57, 50, 97, 87, 70, 115, 73, 72, 100, 112, 101, 109, 70, 121, 90, 72, 77, 103, 90, 88, 104, 119, 90, 88, 74, 48, 98, 72, 107, 103, 98, 87, 108, 52, 73, 68, 85, 103, 99, 71, 57, 48, 90, 87, 53, 48, 73, 71, 86, 115, 97, 88, 104, 112, 99, 110, 77, 117, 73, 69, 74, 121, 97, 87, 100, 111, 100, 67, 66, 117, 90, 87, 57, 117, 73, 72, 78, 112, 90, 50, 53, 122, 73, 71, 90, 115, 89, 88, 78, 111, 73, 67, 74, 80, 85, 69, 86, 79, 73, 68, 73, 48, 76, 122, 99, 105, 73, 71, 108, 117, 73, 72, 82, 111, 90, 83, 66, 116, 97, 88, 78, 48, 101, 83, 66, 117, 97, 87, 100, 111, 100, 67, 66, 104, 97, 88, 73, 115, 73, 71, 108, 115, 98, 72, 86, 116, 97, 87, 53, 104, 100, 71, 108, 117, 90, 121, 65, 52, 73, 72, 90, 112, 98, 110, 82, 104, 90, 50, 85, 103, 89, 50, 70, 121, 99, 121, 66, 119, 89, 88, 74, 114, 90, 87, 81, 103, 89, 87, 120, 118, 98, 109, 99, 103, 84, 87, 70, 112, 98, 105, 66, 84, 100, 72, 74, 108, 90, 88, 81, 117, 73, 69, 69, 103, 90, 50, 86, 117, 100, 71, 120, 108, 73, 71, 74, 121, 90, 87, 86, 54, 90, 83, 66, 106, 89, 88, 74, 121, 97, 87, 86, 122, 73, 72, 82, 111, 90, 83, 66, 104, 99, 109, 57, 116, 89, 83, 66, 118, 90, 105, 66, 109, 99, 109, 86, 122, 97, 67, 66, 106, 98, 50, 90, 109, 90, 87, 85, 103, 89, 87, 53, 107, 73, 72, 100, 104, 99, 109, 48, 103, 89, 50, 108, 117, 98, 109, 70, 116, 98, 50, 52, 103, 99, 109, 57, 115, 98, 72, 77, 103, 90, 110, 74, 118, 98, 83, 66, 75, 98, 50, 85, 110, 99, 121, 66, 69, 97, 87, 53, 108, 99, 105, 119, 103, 90, 87, 53, 48, 97, 87, 78, 112, 98, 109, 99, 103, 78, 105, 66, 122, 98, 71, 86, 108, 99, 72, 107, 103, 100, 72, 74, 49, 89, 50, 116, 108, 99, 110, 77, 103, 100, 71, 56, 103, 99, 51, 82, 118, 99, 67, 66, 109, 98, 51, 73, 103, 89, 83, 66, 115, 89, 88, 82, 108, 76, 87, 53, 112, 90, 50, 104, 48, 73, 72, 78, 117, 89, 87, 78, 114, 76, 105, 66, 78, 90, 87, 70, 117, 100, 50, 104, 112, 98, 71, 85, 115, 73, 68, 69, 120, 73, 71, 49, 112, 99, 50, 78, 111, 97, 87, 86, 50, 98, 51, 86, 122, 73, 71, 116, 112, 100, 72, 82, 108, 98, 110, 77, 103, 99, 71, 120, 104, 101, 87, 90, 49, 98, 71, 120, 53, 73, 71, 78, 111, 89, 88, 78, 108, 73, 71, 69, 103, 89, 109, 70, 115, 98, 67, 66, 118, 90, 105, 66, 53, 89, 88, 74, 117, 73, 71, 70, 106, 99, 109, 57, 122, 99, 121, 66, 78, 99, 110, 77, 117, 73, 69, 112, 118, 97, 71, 53, 122, 98, 50, 52, 110, 99, 121, 66, 119, 98, 51, 74, 106, 97, 67, 119, 103, 100, 71, 104, 108, 97, 88, 73, 103, 89, 87, 53, 48, 97, 87, 78, 122, 73, 71, 57, 105, 99, 50, 86, 121, 100, 109, 86, 107, 73, 71, 74, 53, 73, 68, 73, 103, 100, 50, 108, 122, 90, 83, 66, 118, 98, 71, 81, 103, 98, 51, 100, 115, 99, 121, 66, 119, 90, 88, 74, 106, 97, 71, 86, 107, 73, 71, 57, 117, 73, 71, 69, 103, 98, 109, 86, 104, 99, 109, 74, 53, 73, 71, 57, 104, 97, 121, 66, 48, 99, 109, 86, 108, 76, 103, 61, 61
    ];
    let result:[u8; 610] = STANDARD.decode(input);
    let expected = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox. Zany quilters fabricate 9 cozy blankets, as 3 jovial wizards expertly mix 5 potent elixirs. Bright neon signs flash \"OPEN 24/7\" in the misty night air, illuminating 8 vintage cars parked along Main Street. A gentle breeze carries the aroma of fresh coffee and warm cinnamon rolls from Joe's Diner, enticing 6 sleepy truckers to stop for a late-night snack. Meanwhile, 11 mischievous kittens playfully chase a ball of yarn across Mrs. Johnson's porch, their antics observed by 2 wise old owls perched on a nearby oak tree.";

    assert(result == expected.as_bytes());
}

#[test]
fn test_decode_standard() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = STANDARD.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 95, offset 0")]
fn test_decode_underscore_with_standard() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let _: [u8; 0] = STANDARD.decode(input);
}

#[test]
fn test_decode_url_safe() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 47, offset 0")]
fn test_decode_slash_with_url_safe() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let _: [u8; 0] = URL_SAFE.decode(input);
}

#[test]
fn test_decode_standard_no_pad() {
    // f
    let input: [u8; 2] = [90, 103];
    let expected: [u8; 1] = [102];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 3] = [90, 109, 56];
    let expected: [u8; 2] = [102, 111];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // test decoding / and +
    let input: [u8; 3] = [47, 43, 65];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // longer than one chunk for processing, with one (omitted) padding char
    // Ascii string: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    let input: [u8; 59] = [
        82, 51, 104, 78, 98, 71, 100, 51, 84, 71, 108, 53, 99, 71, 53, 87, 99, 107, 85, 121, 81,
        122, 66, 84, 90, 106, 82, 53, 101, 109, 104, 106, 86, 49, 82, 114, 81, 87, 104, 84, 87,
        106, 85, 114, 86, 48, 86, 83, 97, 69, 116, 111, 87, 72, 82, 115, 86, 84, 48
    ];
    let expected: [u8; 43] = [
        71, 120, 77, 108, 103, 119, 76, 105, 121, 112, 110, 86, 114, 69, 50, 67, 48, 83, 102, 52,
        121, 122, 104, 99, 87, 84, 107, 65, 104, 83, 90, 53, 43, 87, 69, 82, 104, 75, 104, 88, 116,
        108, 85
    ];

    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // longer than one chunk for processing, with two (omitted) padding chars=
    let expected = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox. Zany quilters fabricate 9 cozy blankets, as 3 jovial wizards expertly mix 5 potent elixirs. Bright neon signs flash \"OPEN 24/7\" in the misty night air, illuminating 8 vintage cars parked along Main Street. A gentle breeze carries the aroma of fresh coffee and warm cinnamon rolls from Joe's Diner, enticing 6 sleepy truckers to stop for a late-night snack. Meanwhile, 11 mischievous kittens playfully chase a ball of yarn across Mrs. Johnson's porch, their antics observed by 2 wise old owls perched on a nearby oak tree.";

    let input: [u8; 814] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73, 71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73, 72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 119, 103, 100, 50, 104, 112, 98, 71, 85, 103, 78, 68, 73, 103, 99, 109, 70, 50, 90, 87, 53, 122, 73, 72, 66, 108, 99, 109, 78, 111, 73, 71, 70, 48, 98, 51, 65, 103, 89, 83, 66, 121, 100, 88, 78, 48, 101, 83, 66, 116, 89, 87, 108, 115, 89, 109, 57, 52, 76, 105, 66, 97, 89, 87, 53, 53, 73, 72, 70, 49, 97, 87, 120, 48, 90, 88, 74, 122, 73, 71, 90, 104, 89, 110, 74, 112, 89, 50, 70, 48, 90, 83, 65, 53, 73, 71, 78, 118, 101, 110, 107, 103, 89, 109, 120, 104, 98, 109, 116, 108, 100, 72, 77, 115, 73, 71, 70, 122, 73, 68, 77, 103, 97, 109, 57, 50, 97, 87, 70, 115, 73, 72, 100, 112, 101, 109, 70, 121, 90, 72, 77, 103, 90, 88, 104, 119, 90, 88, 74, 48, 98, 72, 107, 103, 98, 87, 108, 52, 73, 68, 85, 103, 99, 71, 57, 48, 90, 87, 53, 48, 73, 71, 86, 115, 97, 88, 104, 112, 99, 110, 77, 117, 73, 69, 74, 121, 97, 87, 100, 111, 100, 67, 66, 117, 90, 87, 57, 117, 73, 72, 78, 112, 90, 50, 53, 122, 73, 71, 90, 115, 89, 88, 78, 111, 73, 67, 74, 80, 85, 69, 86, 79, 73, 68, 73, 48, 76, 122, 99, 105, 73, 71, 108, 117, 73, 72, 82, 111, 90, 83, 66, 116, 97, 88, 78, 48, 101, 83, 66, 117, 97, 87, 100, 111, 100, 67, 66, 104, 97, 88, 73, 115, 73, 71, 108, 115, 98, 72, 86, 116, 97, 87, 53, 104, 100, 71, 108, 117, 90, 121, 65, 52, 73, 72, 90, 112, 98, 110, 82, 104, 90, 50, 85, 103, 89, 50, 70, 121, 99, 121, 66, 119, 89, 88, 74, 114, 90, 87, 81, 103, 89, 87, 120, 118, 98, 109, 99, 103, 84, 87, 70, 112, 98, 105, 66, 84, 100, 72, 74, 108, 90, 88, 81, 117, 73, 69, 69, 103, 90, 50, 86, 117, 100, 71, 120, 108, 73, 71, 74, 121, 90, 87, 86, 54, 90, 83, 66, 106, 89, 88, 74, 121, 97, 87, 86, 122, 73, 72, 82, 111, 90, 83, 66, 104, 99, 109, 57, 116, 89, 83, 66, 118, 90, 105, 66, 109, 99, 109, 86, 122, 97, 67, 66, 106, 98, 50, 90, 109, 90, 87, 85, 103, 89, 87, 53, 107, 73, 72, 100, 104, 99, 109, 48, 103, 89, 50, 108, 117, 98, 109, 70, 116, 98, 50, 52, 103, 99, 109, 57, 115, 98, 72, 77, 103, 90, 110, 74, 118, 98, 83, 66, 75, 98, 50, 85, 110, 99, 121, 66, 69, 97, 87, 53, 108, 99, 105, 119, 103, 90, 87, 53, 48, 97, 87, 78, 112, 98, 109, 99, 103, 78, 105, 66, 122, 98, 71, 86, 108, 99, 72, 107, 103, 100, 72, 74, 49, 89, 50, 116, 108, 99, 110, 77, 103, 100, 71, 56, 103, 99, 51, 82, 118, 99, 67, 66, 109, 98, 51, 73, 103, 89, 83, 66, 115, 89, 88, 82, 108, 76, 87, 53, 112, 90, 50, 104, 48, 73, 72, 78, 117, 89, 87, 78, 114, 76, 105, 66, 78, 90, 87, 70, 117, 100, 50, 104, 112, 98, 71, 85, 115, 73, 68, 69, 120, 73, 71, 49, 112, 99, 50, 78, 111, 97, 87, 86, 50, 98, 51, 86, 122, 73, 71, 116, 112, 100, 72, 82, 108, 98, 110, 77, 103, 99, 71, 120, 104, 101, 87, 90, 49, 98, 71, 120, 53, 73, 71, 78, 111, 89, 88, 78, 108, 73, 71, 69, 103, 89, 109, 70, 115, 98, 67, 66, 118, 90, 105, 66, 53, 89, 88, 74, 117, 73, 71, 70, 106, 99, 109, 57, 122, 99, 121, 66, 78, 99, 110, 77, 117, 73, 69, 112, 118, 97, 71, 53, 122, 98, 50, 52, 110, 99, 121, 66, 119, 98, 51, 74, 106, 97, 67, 119, 103, 100, 71, 104, 108, 97, 88, 73, 103, 89, 87, 53, 48, 97, 87, 78, 122, 73, 71, 57, 105, 99, 50, 86, 121, 100, 109, 86, 107, 73, 71, 74, 53, 73, 68, 73, 103, 100, 50, 108, 122, 90, 83, 66, 118, 98, 71, 81, 103, 98, 51, 100, 115, 99, 121, 66, 119, 90, 88, 74, 106, 97, 71, 86, 107, 73, 71, 57, 117, 73, 71, 69, 103, 98, 109, 86, 104, 99, 109, 74, 53, 73, 71, 57, 104, 97, 121, 66, 48, 99, 109, 86, 108, 76, 103
    ];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected.as_bytes());
}

#[test]
fn test_decode_url_safe_no_pad() {
    // test decoding _ and -
    let input: [u8; 3] = [95, 45, 65];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE_NO_PAD.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 61, offset 3")]
fn test_decode_standard_no_pad_fail_with_padding() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 61, offset 3")]
fn test_decode_url_safe_no_pad_fail_with_padding() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected:[u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE_NO_PAD.decode(input);
    assert(result == expected);
}
