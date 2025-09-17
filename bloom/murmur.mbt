/// The bloom library relied on the excellent murmur library
/// by Sébastien Paolacci. Unfortunately, it involved some heap
/// allocation. We want to avoid any heap allocation whatsoever
/// in the hashing process. To preserve backward compatibility, we roll
/// our own hashing functions. They are designed to be strictly equivalent
/// to Paolacci's implementation.

///|
let c1 : UInt64 = 0x87c37b91114253d5

///|
let c2 : UInt64 = 0x4cf5ad432745937f

///|
let block_size = 16

///|
/// Digest128 represents a partial evaluation of a 128 bits hash.
priv struct Digest128 {
  mut h1 : UInt64 // Unfinalized running hash part 1.
  mut h2 : UInt64 // Unfinalized running hash part 2.
}

///|
/// bmix will hash blocks (16 bytes)
fn Digest128::bmix(self : Digest128, bv : Bytes) -> Unit {
  let n = bv.length() / block_size
  for i = 0; i < n; i = i + 1 {
    let base_index = i * block_size
    let num1 = bv[base_index:base_index + 8].to_uint64_le()
    let num2 = bv[base_index + 8:base_index + 16].to_uint64_le()
    self.bmix_words(num1, num2)
  }
}

///|
/// Perform circular left shift on UInt64 numbers
fn rotate_left(num : UInt64, shift : Int) -> UInt64 {
  let shift = shift % 64
  if shift == 0 {
    return num
  }
  (num << shift) | (num >> (64 - shift))
}

///|
/// bmix_words will hash two 64-bit words (16 bytes)
fn Digest128::bmix_words(
  self : Digest128,
  num1 : UInt64,
  num2 : UInt64,
) -> Unit {
  let mut h1 = self.h1
  let mut h2 = self.h2
  let mut k1 = num1 * c1
  let mut k2 = num2 * c2
  k1 = rotate_left(k1, 31)
  k1 = k1 * c2
  h1 = h1 ^ k1
  h1 = rotate_left(h1, 27)
  h1 = h1 + h2
  h1 = h1 * 5 + 0x52dce729
  k2 = rotate_left(k2, 33)
  k2 = k2 * c1
  h2 = h2 ^ k2
  h2 = rotate_left(h2, 31)
  h2 = h2 + h1
  h2 = h2 * 5 + 0x38495ab5
  self.h1 = h1
  self.h2 = h2
}

///|
/// sum128 computers two 64-bit hash value. It is assumed that
/// bmix was first called on the data to process complete blocks
/// of 16 bytes. The 'tail' is a slice representing the 'tail' (leftover
/// elements, fewer than 16). If pad_tail is true, we make it seem like
/// there is an extra element with value 1 appended to the tail.
/// The length parameter represents the full length of the data (including
/// the blocks of 16 bytes, and, if pad_tail is true, an extra byte).
fn Digest128::sum128(
  self : Digest128,
  pad_tail : Bool,
  length : UInt,
  tail : Bytes,
) -> (UInt64, UInt64) {
  let mut h1 = self.h1
  let mut h2 = self.h2
  let mut k1 : UInt64 = 0
  let mut k2 : UInt64 = 0
  if pad_tail {
    let remainder = (tail.length() + 1) & 15
    match remainder {
      15 => k2 = k2 ^ (1UL << 48)
      14 => k2 = k2 ^ (1UL << 40)
      13 => k2 = k2 ^ (1UL << 32)
      12 => k2 = k2 ^ (1UL << 24)
      11 => k2 = k2 ^ (1UL << 16)
      10 => k2 = k2 ^ (1UL << 8)
      9 => {
        k2 = k2 ^ 1UL
        k2 = k2 * c2
        k2 = rotate_left(k2, 33)
        k2 = k2 * c1
        h2 = h2 ^ k2
      }
      8 => k1 = k1 ^ (1UL << 56)
      7 => k1 = k1 ^ (1UL << 48)
      6 => k1 = k1 ^ (1UL << 40)
      5 => k1 = k1 ^ (1UL << 32)
      4 => k1 = k1 ^ (1UL << 24)
      3 => k1 = k1 ^ (1UL << 16)
      2 => k1 = k1 ^ (1UL << 8)
      1 => {
        k1 = k1 ^ 1UL
        k1 = k1 * c1
        k1 = rotate_left(k1, 31)
        k1 = k1 * c2
        h1 = h1 ^ k1
      }
      _ => ()
    }
  }
  let remainder = tail.length() & 15
  if remainder >= 15 {
    k2 = k2 ^ (tail[14].to_uint64() << 48)
  }
  if remainder >= 14 {
    k2 = k2 ^ (tail[13].to_uint64() << 40)
  }
  if remainder >= 13 {
    k2 = k2 ^ (tail[12].to_uint64() << 32)
  }
  if remainder >= 12 {
    k2 = k2 ^ (tail[11].to_uint64() << 24)
  }
  if remainder >= 11 {
    k2 = k2 ^ (tail[10].to_uint64() << 16)
  }
  if remainder >= 10 {
    k2 = k2 ^ (tail[9].to_uint64() << 8)
  }
  if remainder >= 9 {
    k2 = k2 ^ tail[8].to_uint64()
    k2 = k2 * c2
    k2 = rotate_left(k2, 33)
    k2 = k2 * c1
    h2 = h2 ^ k2
  }
  if remainder >= 8 {
    k1 = k1 ^ (tail[7].to_uint64() << 56)
  }
  if remainder >= 7 {
    k1 = k1 ^ (tail[6].to_uint64() << 48)
  }
  if remainder >= 6 {
    k1 = k1 ^ (tail[5].to_uint64() << 40)
  }
  if remainder >= 5 {
    k1 = k1 ^ (tail[4].to_uint64() << 32)
  }
  if remainder >= 4 {
    k1 = k1 ^ (tail[3].to_uint64() << 24)
  }
  if remainder >= 3 {
    k1 = k1 ^ (tail[2].to_uint64() << 16)
  }
  if remainder >= 2 {
    k1 = k1 ^ (tail[1].to_uint64() << 8)
  }
  if remainder >= 1 {
    k1 = k1 ^ tail[0].to_uint64()
    k1 = k1 * c1
    k1 = rotate_left(k1, 31)
    k1 = k1 * c2
    h1 = h1 ^ k1
  }
  h1 = h1 ^ length.to_uint64()
  h2 = h2 ^ length.to_uint64()
  h1 = h1 + h2
  h2 = h2 + h1
  h1 = fmix64(h1)
  h2 = fmix64(h2)
  h1 = h1 + h2
  h2 = h2 + h1
  return (h1, h2)
}

///|
fn fmix64(k : UInt64) -> UInt64 {
  let mut k = k ^ (k >> 33)
  k = k * 0xff51afd7ed558ccd
  k = k ^ (k >> 33)
  k = k * 0xc4ceb9fe1a85ec53
  k = k ^ (k >> 33)
  return k
}

///|
fn Digest128::new() -> Digest128 {
  { h1: 0, h2: 0 }
}

///|
/// sum256 will compute 4 64-bit hash values from the input.
/// It is designed to never allocate memory on the heap. So it
/// works without any byte buffer whatsoever.
//typealias (UInt64, UInt64, UInt64, UInt64) Hash256
fn Digest128::sum256(
  self : Digest128,
  data : Bytes,
) -> (UInt64, UInt64, UInt64, UInt64) {
  // Process as many bytes as possible.
  self.bmix(data)

  // We have enough to compute the first two 64-bit numbers
  let length = data.length()
  let tail_length = length % block_size
  let tail = data[length - tail_length:].to_bytes()
  let (hash1, hash2) = self.sum128(false, length.reinterpret_as_uint(), tail)

  // Next we want to 'virtually' append 1 to the input, but,
  // we do not want to append to an actual array!!!
  if tail_length == block_size - 1 {
    // We are left with no tail!!!
    let word1 = tail[0:8].to_uint64_le()
    let mut word2 = tail[8:12].to_uint_le().to_uint64()
    word2 = word2 |
      (tail[12].to_uint64() << 32) |
      (tail[13].to_uint64() << 40) |
      (tail[14].to_uint64() << 48)

    // We append 1.
    word2 = word2 | (1UL << 56)

    // We process the resulting 2 words.
    self.bmix_words(word1, word2)
    let (hash3, hash4) = self.sum128(
      false,
      (length + 1).reinterpret_as_uint(),
      b"",
    )
    return (hash1, hash2, hash3, hash4)
  } else {
    // We still have a tail (fewer than 15 bytes) but we
    // need to append '1' to it.
    let (hash3, hash4) = self.sum128(
      true,
      (length + 1).reinterpret_as_uint(),
      tail,
    )
    return (hash1, hash2, hash3, hash4)
  }
}
