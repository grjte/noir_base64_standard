// Encodings use the standard alphabet specified in RFC 4648 
// (https://datatracker.ietf.org/doc/html/rfc4648#section-4):
//
//    A 65-character subset of US-ASCII is used, enabling 6 bits to be
//    represented per printable character.  (The extra 65th character, "=",
//    is used to signify a special processing function.)
// 
//    The encoding process represents 24-bit groups of input bits as output
//    strings of 4 encoded characters.  Proceeding from left to right, a
//    24-bit input group is formed by concatenating 3 8-bit input groups.
//    These 24 bits are then treated as 4 concatenated 6-bit groups, each
//    of which is translated into a single character in the base 64
//    alphabet.
// 
//    Each 6-bit group is used as an index into an array of 64 printable
//    characters.  The character referenced by the index is placed in the
//    output string.

mod encoder;
pub use encoder::{
    STANDARD as ENCODER_STANDARD, STANDARD_NO_PAD as ENCODER_STANDARD_NO_PAD,
    URL_SAFE as ENCODER_URL_SAFE, URL_SAFE_NO_PAD as ENCODER_URL_SAFE_NO_PAD
};

mod decoder;
pub use decoder::{
    STANDARD as DECODER_STANDARD, STANDARD_NO_PAD as DECODER_STANDARD_NO_PAD,
    URL_SAFE as DECODER_URL_SAFE, URL_SAFE_NO_PAD as DECODER_URL_SAFE_NO_PAD
};

mod defaults {
    global BASE64_PADDING_CHAR: u8 = 61;
    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // we pack 40 base64 values into a field element and convert into 30 bytes
    global BASE64_PER_FIELD_ELEM: u32 = 40;
    global BYTES_PER_FIELD_ELEM: u32 = 30;
}

#[test]
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg==";

    let encoded:[u8; 120] = ENCODER_STANDARD.encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = DECODER_STANDARD.decode(encoded);
    assert(decoded == input.as_bytes());
}
