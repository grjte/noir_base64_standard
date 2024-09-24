# base64_standard

Base64 encoding/decoding in Noir using the standard Base64 alphabet. This was written as a binary rather than a library for ease of testing & demonstration, but
could be easily converted.

## Usage

### `fn encode`
Takes an arbitrary byte array as input, encodes it in Base64 according to the standard Base64 alphabet, then encodes each Base64 character into UTF-8 to return a byte array representing the Base64 encoding.

### `fn decode`
Takes a utf-8 byte array that encodes a Base64 string and decodes it into bytes.

## Example usage
(see tests in `lib.nr` or `fn main` for more examples)

```
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg==";

    let encoded:[u8; 120] = encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = decode(encoded);
    assert(decoded == input.as_bytes());
}
```
