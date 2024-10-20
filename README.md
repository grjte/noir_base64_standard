# base64_standard

A Base64 encoding/decoding library written in Noir which can encode arbitrary byte arrays and decode UTF-8 byte arrays that encode Base64 strings (e.g. `"SGVsbG8gV29ybGQ=".as_bytes()`).

## Usage

### Configuration
Start by selecting the encoder or decoder for your configuration. These are defined separately so that only one lookup table will be instantiated at a time, since many cases will require either an encoder or a decoder but not both.

RFC 4648 specifies multiple alphabets, including the [standard Base 64 Alphabet](https://datatracker.ietf.org/doc/html/rfc4648#section-4) known as `base64` and the ["URL and Filename Safe Alphabet"](https://datatracker.ietf.org/doc/html/rfc4648#section-5) known as `base64url`. It also specifies that [padding](https://datatracker.ietf.org/doc/html/rfc4648#section-3.2) should be required in the general case but can be explicitly omitted as an option.

Available encoder configurations:
- `ENCODER_STANDARD`: uses the standard alphabet (base64) and adds padding.
- `ENCODER_STANDARD_NO_PAD`: uses the standard alphabet (base64), but omits padding.
- `ENCODER_URL_SAFE`: uses the "URL and Filename Safe Alphabet" (base64url) and adds padding.
- `ENCODER_URL_SAFE_NO_PAD`: uses the "URL and Filename Safe Alphabet" (base64url), but omits padding.

Available decoder configurations:
- `DECODER_STANDARD`: uses the standard alphabet (base64) and expects correct padding.
- `DECODER_STANDARD_NO_PAD`: uses the standard alphabet (base64), but expects all padding characters to have been stripped. A padding character encoutered during decoding will trigger an error.
- `DECODER_URL_SAFE`: uses the "URL and Filename Safe Alphabet" (base64url) and expects correct padding.
- `DECODER_URL_SAFE_NO_PAD`: uses the "URL and Filename Safe Alphabet" (base64url), but expects all padding characters to have been stripped. A padding character encoutered during decoding will trigger an error.

### `fn encode`
Takes an arbitrary byte array as input, encodes it in Base64 according to the alphabet and padding rules specified by the configuration, then encodes each Base64 character into UTF-8 to return a byte array representing the Base64 encoding.

```
// bytes: [u8; N]
let base64 = ENCODER_STANDARD.encode(bytes);
```

### `fn decode`
Takes a utf-8 byte array that encodes a Base64 string and attempts to decoded it into bytes according to the provided configuration specifying the alphabet and padding rules.

```
// base64: [u8; N]
let bytes = DECODER_STANDARD.decode(base64);
```

## Example usage
(see tests in `lib.nr` for more examples)

```
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg==";

    let encoded:[u8; 120] = ENCODER_STANDARD.encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = DECODER_STANDARD.decode(encoded);
    assert(decoded == input.as_bytes());
}
```
