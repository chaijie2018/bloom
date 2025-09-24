///|
/// BitVector is an immutable bit vector data structure for compact and efficient storage and manipulation of boolean sequences.
/// It provides a series of bit operations while maintaining immutability (all modification operations return new BitVector instances).
pub(all) struct BitVector {
  /// Total number of bits in the vector
  length : Int
  /// Record the valid bits in the last UInt64
  tail_mask : UInt64
  /// Underlying array storing bit data, each UInt64 stores 64 bits
  data : Array[UInt64]
} derive(Eq, Show)

///|
const UINT64_MAX : UInt64 = 0xffff_ffff_ffff_ffff

///|
/// Calculates the number of UInt64 needed for length bits
fn words_needed(length : Int) -> Int {
  if length <= 0 {
    abort("The length of BitVector should be positive!")
  }
  (length + 63) >> 6
}

///|
/// Calculate the valid bits mask for the last UInt64
fn tail_mask(length : Int) -> UInt64 {
  let remainder = length & 63
  if remainder == 0 {
    return UINT64_MAX
  }
  (1UL << remainder) - 1UL
}

///|
fn bit_mask(index : Int) -> UInt64 {
  let index_in_word = index & 63
  1UL << index_in_word
}

///|
/// Creates a bit vector of specified length with all bits set to 0
pub fn BitVector::new(length : Int) -> BitVector {
  if length < 0 {
    abort("BitVector length must be positive")
  }
  let data = Array::make(words_needed(length), 0UL)
  let tail_mask = tail_mask(length)
  { length, tail_mask, data }
}

///|
/// Creates a bit vector of specified length with all bits set to 1
pub fn BitVector::ones(length : Int) -> BitVector {
  let bv = BitVector::new(length)
  bv.flip_all()
  bv
}

///|
/// From is a constructor used to create a BitVector from an array of UInt64
pub fn BitVector::from(buf : Array[UInt64]) -> BitVector {
  return BitVector::from_with_length(buf, buf.length() * 64)
}

///|
/// Creates a bit vector from an array of integers
pub fn BitVector::from_with_length(
  ints : Array[UInt64],
  length : Int,
) -> BitVector {
  if length <= 0 {
    abort("BitVector length must be positive")
  }
  let num_ints = (length + 63) >> 6
  if ints.length() < num_ints {
    abort("Array too small for specified length")
  }
  let tail_mask = tail_mask(length)
  let data = ints.copy()
  { length, tail_mask, data }
}

///|
/// Creates a bit vector from an array of booleans
pub fn BitVector::from_bools(bools : Array[Bool]) -> BitVector {
  let length = bools.length()
  let bv = BitVector::new(length)

  // Set each bit
  for i in 0..<length {
    if bools[i] {
      let word_idx = i >> 6
      bv.data[word_idx] = bv.data[word_idx] | bit_mask(i)
    }
  }
  bv
}

///|
/// Creates a bit vector from a string ("1" for set bits, "0" for clear bits)
pub fn BitVector::from_string(s : String) -> BitVector {
  let length = s.length()
  let bv = BitVector::new(length)
  for i in 0..<length {
    if s.get_char(i).unwrap() == '1' {
      let word_idx = i >> 6
      let bit_idx = i & 63
      bv.data[word_idx] = bv.data[word_idx] | ((1).to_uint64() << bit_idx)
    } else if s.get_char(i).unwrap() != '0' {
      abort("String must contain only '0' and '1' characters")
    }
  }
  bv
}

//-----------------------------------------------------------------------------
// Basic Bit Operations
//-----------------------------------------------------------------------------

///|
/// Gets the boolean value at the specified position in the bit vector
pub fn BitVector::get(self : BitVector, index : Int) -> Bool {
  if index < 0 || index >= self.length {
    abort("Index is out of bounds")
  }
  let word_idx = index >> 6
  (self.data[word_idx] & bit_mask(index)) != 0
}

///|
/// Set the bit at the specified position to 1
pub fn BitVector::set(self : BitVector, index : Int) -> Unit {
  if index < 0 || index >= self.length {
    abort("Index is out of bounds")
  }
  let word_idx = index >> 6
  self.data[word_idx] = self.data[word_idx] | bit_mask(index)
}

///|
/// Flips the bit at the specified position
pub fn BitVector::flip(self : BitVector, index : Int) -> Unit {
  if index < 0 || index >= self.length {
    abort("Index is out of bounds")
  }
  let word_idx = index >> 6
  self.data[word_idx] = self.data[word_idx] ^ bit_mask(index)
}

///|
/// Flips all bits in the vector
pub fn BitVector::flip_all(self : BitVector) -> Unit {
  for i in 0..<self.data.length() {
    self.data[i] = self.data[i] ^ UINT64_MAX
  }
}

///|
// Clear bit i to 0. This never cause a memory allocation.
pub fn BitVector::clear(self : BitVector, index : Int) -> Unit {
  if index < 0 {
    abort("index should be greater than or equal to 0")
  }
  if index >= self.length {
    return
  }
  let word_idx = index >> 6
  self.data[word_idx] = self.data[word_idx] & (UINT64_MAX ^ bit_mask(index))
}

///|
// Clear the entire BitSet. It does not free the memory.
pub fn BitVector::clear_all(self : BitVector) -> Unit {
  for i in 0..<self.data.length() {
    self.data[i] = 0UL
  }
}

//-----------------------------------------------------------------------------
// Logical Operations
//-----------------------------------------------------------------------------

///|
/// Performs bitwise AND operation on bit vectors, returns a new bit vector
pub fn BitVector::intersection(
  self : BitVector,
  other : BitVector,
) -> BitVector {
  if self.length != other.length {
    abort("BitVectors must have the same length for logical operations")
  }
  let new_data = Array::make(self.data.length(), 0UL)

  // Perform bitwise AND operation
  for i in 0..<new_data.length() {
    new_data[i] = self.data[i] & other.data[i]
  }
  { data: new_data, length: self.length, tail_mask: self.tail_mask }
}

///|
/// Performs bitwise OR operation on bit vectors, returns a new bit vector
pub fn BitVector::union(self : BitVector, other : BitVector) -> BitVector {
  if self.length != other.length {
    abort("BitVectors must have the same length for logical operations")
  }
  let new_data = Array::make(self.data.length(), (0).to_uint64())

  // Perform bitwise OR operation
  for i in 0..<new_data.length() {
    new_data[i] = self.data[i] | other.data[i]
  }
  { data: new_data, length: self.length, tail_mask: self.tail_mask }
}

///|
pub fn BitVector::inplace_union(
  self : BitVector,
  other : BitVector,
) -> BitVector {
  if self.length != other.length {
    abort("BitVectors must have the same length for logical operations")
  }

  // Perform bitwise OR operation
  for i in 0..<self.data.length() {
    self.data[i] = self.data[i] | other.data[i]
  }
  self
}

///|
/// Performs bitwise XOR operation on bit vectors, returns a new bit vector
pub fn BitVector::difference(self : BitVector, other : BitVector) -> BitVector {
  if self.length != other.length {
    abort("BitVectors must have the same length for logical operations")
  }
  let new_data = Array::make(self.data.length(), (0).to_uint64())

  // Perform bitwise XOR operation
  for i in 0..<new_data.length() {
    new_data[i] = self.data[i] ^ other.data[i]
  }
  { data: new_data, length: self.length, tail_mask: self.tail_mask }
}

///|
/// Equal tests the equivalence of two BitVector.
/// False if they are of different sizes, otherwise true.
/// only if all the same bits are set.
pub fn BitVector::equal(self : BitVector, other : BitVector) -> Bool {
  if self.length != other.length {
    return false
  }

  // Process all UInt64 except the last one
  for i = 0; i < self.data.length() - 1; i = i + 1 {
    if self.data[i] != other.data[i] {
      return false
    }
  }

  // Process the last UInt64, only consider the valid bits
  (self.data[self.data.length() - 1] & self.tail_mask) ==
  (other.data[self.data.length() - 1] & other.tail_mask)
}

//-----------------------------------------------------------------------------
// Bit Counting and Finding
//-----------------------------------------------------------------------------

///|
/// Counts the number of 1s in the bit vector
pub fn BitVector::count_ones(self : BitVector) -> Int {
  let mut count = 0

  // Process all UInt64 except the last one
  for i in 0..<(self.data.length() - 1) {
    count += pop_count(self.data[i])
  }

  // Process the last UInt64, only count the valid bits
  let last = self.data[self.data.length() - 1] & self.tail_mask
  count + pop_count(last)
}

///|
/// Counts the number of 0s in the bit vector
pub fn BitVector::count_zeros(self : BitVector) -> Int {
  self.length - self.count_ones()
}

///|
/// Helper function: Count the number of 1s in an UInt64
fn pop_count(x : UInt64) -> Int {
  let mut n = x
  let mut count = 0
  while n != 0 {
    n = n & (n - 1)
    count += 1
  }
  count
}

///|
/// Finds the index of the first bit set to 1 in the vector, returns -1 if none
pub fn BitVector::find_first_set(self : BitVector) -> Int {
  for i in 0..<self.data.length() {
    if self.data[i] != 0 {
      let word = self.data[i]
      let bit_pos = trailing_zeros(word)
      return (i << 6) + bit_pos
    }
  }
  -1
}

///|
/// Finds the index of the first bit set to 0 in the integer, returns -1 if none
pub fn lowest_unset_bit(x : UInt64) -> Int {
  if x == UINT64_MAX {
    return 64 // indicates no 0 bits
  }
  let mut pos = 0
  let mut val = x
  while (val & 1) == 1 {
    pos += 1
    val = val >> 1
  }
  pos
}

///|
/// Helper function: Find the position of the lowest 1 bit in an integer
pub fn trailing_zeros(x : UInt64) -> Int {
  if x == 0 {
    return -1
  }
  let mut pos = 0
  let mut val = x
  while (val & 1) == 0 {
    pos += 1
    val = val >> 1
  }
  pos
}

//-----------------------------------------------------------------------------
// Serialization
//-----------------------------------------------------------------------------

///|
/// Serialize from BitVector to Bytes
pub fn BitVector::marshal_bytes(self : BitVector) -> Bytes {
  // Storage capacity occupied by a BitVector struct
  let capacity = 8 * words_needed(self.length) + 12
  let buf = @buffer.new(size_hint=capacity)
  buf.write_int_le(self.length)
  buf.write_uint64_le(self.tail_mask)
  self.data.iter().each(x => buf.write_uint64_le(x))
  buf.to_bytes()
}

///|
/// Serialize from Bytes to BitVector
pub fn BitVector::unmarshal_bytes(bytes : Bytes) -> BitVector {
  let length = bytes[0:4].to_int_le()
  let tail_mask = bytes[4:12].to_uint64_le()
  let words_needed = words_needed(length)
  let data = Array::make(words_needed, 0UL)
  let mut offset = 12
  for i in 0..<words_needed {
    data[i] = bytes[offset:offset + 8].to_uint64_le()
    offset += 8
  }
  { length, tail_mask, data }
}

///|
/// Converts the bit vector to a string representation, 1 for set bits, 0 for clear bits
pub fn BitVector::to_string(self : BitVector) -> String {
  let mut result = ""
  for i in 0..<self.length {
    if self.get(i) {
      result = result + "1"
    } else {
      result = result + "0"
    }
  }
  result
}

///|
/// Converts the bit vector to an array of booleans
pub fn BitVector::to_bools(self : BitVector) -> Array[Bool] {
  let result = Array::make(self.length, false)
  for i in 0..<self.length {
    if self.get(i) {
      result[i] = true
    }
  }
  result
}

//-----------------------------------------------------------------------------
// Utility Methods
//-----------------------------------------------------------------------------

///|
/// Checks if the bit vector is all zeros
pub fn BitVector::is_all_zeros(self : BitVector) -> Bool {
  for i = 0; i < self.data.length() - 1; i = i + 1 {
    if self.data[i] != 0 {
      return false
    }
  }

  // Check the last UInt64
  (self.data[self.data.length() - 1] & self.tail_mask) == 0
}

///|
/// Checks if the bit vector is all ones
pub fn BitVector::is_all_ones(self : BitVector) -> Bool {
  for i = 0; i < self.data.length() - 1; i = i + 1 {
    if self.data[i] != UINT64_MAX {
      return false
    }
  }

  // Check the last UInt64
  (self.data[self.data.length() - 1] & self.tail_mask) == self.tail_mask
}
