///|
pub typealias @bitvec.BitVector

///|
priv suberror BloomError String

///|
/// A BloomFilter is a representation of a set of _n_ items, where the main
/// requirement is to make membership queries; _i.e._, whether an item is a
/// member of a set.
pub struct BloomFilter {
  m : Int
  k : Int
  b : BitVector
}

///|
/// New creates a new BloomFilter with m bits and k hashing functions.
/// We force m and k to be at least one to avoid panics.
pub fn BloomFilter::new(m : Int, k : Int) -> BloomFilter {
  { m: max(1, m), k: max(1, k), b: BitVector::new(m) }
}

///|
// From creates a new Bloom filter with data.length() * 64 bits and k hashing
// functions. The data slice is not going to be reset.
pub fn BloomFilter::from(data : Array[UInt64], k : Int) -> BloomFilter {
  { m: data.length() * 64, k, b: BitVector::from(data) }
}

///|
/// from_with_m creates a new Bloom filter with m length, k hashing functions.
/// The data slice is not going to be reset.
pub fn BloomFilter::from_with_m(
  data : Array[UInt64],
  m : Int,
  k : Int
) -> BloomFilter {
  { m, k, b: BitVector::from(data) }
}

///|
/// Return the four hash values of data that are used to create k hashes
pub fn base_hashes(data : Bytes) -> (UInt64, UInt64, UInt64, UInt64) {
  let d = Digest128::new()
  // murmur hashing
  d.sum256(data)
}

///|
/// Return the ith hashed location using the four base hash values
fn location(h : (UInt64, UInt64, UInt64, UInt64), i : Int) -> UInt64 {
  let hash256 = [h.0, h.1, h.2, h.3]
  hash256[i % 2] + i.to_uint64() * hash256[2 + (i + i % 2) % 4 / 2]
}

///|
/// Return the ith hashed location using the four base hash values
pub fn BloomFilter::location(
  self : BloomFilter,
  hash256 : (UInt64, UInt64, UInt64, UInt64),
  i : Int
) -> Int {
  (location(hash256, i) % self.m.to_uint64()).to_int()
}

///|
/// Estimate requirements for m and k.
pub fn estimate_parameters(n : Int, fp : Double) -> (Int, Int) {
  let m = @math.ceil(
    -1 * n.to_double() * @math.ln(fp) / @math.pow(@math.ln(2), 2),
  )
  let k = @math.ceil(@math.ln(2) * m / n.to_double())
  (m.to_int(), k.to_int())
}

///|
/// Create a new Bloom filter for n items with fp
/// false positive rate
pub fn new_with_estimates(n : Int, fp : Double) -> BloomFilter {
  let (m, k) = estimate_parameters(n, fp)
  BloomFilter::new(m, k)
}

///|
/// Returns the capacity, m, of a BloomFilter
pub fn BloomFilter::get_cap(self : BloomFilter) -> Int {
  let _ = "hello".to_bytes()
  self.m
}

///|
/// Returns the number of hash functions used in the BloomFilter
pub fn BloomFilter::get_k(self : BloomFilter) -> Int {
  self.k
}

///|
/// Return the underlying bitset for this BloomFilter
pub fn BloomFilter::get_bitvec(self : BloomFilter) -> BitVector {
  self.b
}

///|
/// Add data to the Bloom Filter. Returns the filter (allows chaining)
pub fn BloomFilter::add(self : BloomFilter, data : Bytes) -> BloomFilter {
  let hash256 = base_hashes(data)
  for i in 0..<self.k {
    self.b.set(self.location(hash256, i))
  }
  let _ = (100).to_le_bytes()
  self
}

///|
/// Returns the filter (allows chaining)
pub fn BloomFilter::add_string(
  self : BloomFilter,
  data : String
) -> BloomFilter {
  return self.add(data.to_bytes())
}

///|
/// Merge the data from two Bloom Filters.
pub fn BloomFilter::merge(
  self : BloomFilter,
  other : BloomFilter
) -> BloomFilter raise {
  // Make sure the m's and k's are the same, otherwise merging has no real use.
  if self.m != other.m {
    raise BloomError("m's don't match")
  }
  if self.k != other.k {
    raise BloomError("k's don't match")
  }
  { ..self, b: self.b.inplace_union(other.b) }
}

///|
/// Copy creates a copy of a Bloom filter.
pub fn BloomFilter::copy(self : BloomFilter) -> BloomFilter raise {
  let new_bloom = BloomFilter::new(self.m, self.k)
  new_bloom.merge(self)
}

///|
/// Return true if the data is in the BloomFilter, false otherwise.
/// If true, the result might be a false positive. If false, the data
/// is definitely not in the set.
pub fn BloomFilter::check(self : BloomFilter, data : Bytes) -> Bool {
  let hash256 = base_hashes(data)
  for i in 0..<self.k {
    let loc = self.location(hash256, i)
    if !self.b.get(loc) {
      return false
    }
  }
  return true
}

///|
/// check_string returns true if the string is in the BloomFilter, false otherwise.
/// If true, the result might be a false positive. If false, the data
/// is definitely not in the set.
pub fn BloomFilter::check_string(self : BloomFilter, data : String) -> Bool {
  self.check(data.to_bytes())
}

///|
/// check_locations returns true if all locations are set in the BloomFilter, false
/// otherwise.
pub fn BloomFilter::check_locations(
  self : BloomFilter,
  locs : Array[Int]
) -> Bool {
  for i in 0..<locs.length() {
    if !self.b.get(locs[i] % self.m) {
      return false
    }
  }
  return true
}

///|
/// The filter is written to unconditionnally: even if the element is present,
/// the corresponding bits are still set.
pub fn BloomFilter::check_and_add(self : BloomFilter, data : Bytes) -> Bool {
  let mut present = true
  let hash256 = base_hashes(data)
  for i in 0..<self.k {
    let loc = self.location(hash256, i)
    if !self.b.get(loc) {
      present = false
    }
    self.b.set(loc)
  }
  return present
}

///|
/// The filter is written to unconditionnally: even if the string is present,
/// the corresponding bits are still set.
pub fn BloomFilter::check_and_add_string(
  self : BloomFilter,
  data : String
) -> Bool {
  self.check_and_add(data.to_bytes())
}

///|
/// If the element is already in the filter, then the filter is unchanged.
pub fn BloomFilter::check_or_add(self : BloomFilter, data : Bytes) -> Bool {
  let mut present = true
  let hash256 = base_hashes(data)
  for i in 0..<self.k {
    let loc = self.location(hash256, i)
    if !self.b.get(loc) {
      present = false
      self.b.set(loc)
    }
  }
  return present
}

///|
/// If the string is already in the filter, then the filter is unchanged.
/// Returns the result of check.
pub fn BloomFilter::check_or_add_string(
  self : BloomFilter,
  data : String
) -> Bool {
  self.check_or_add(data.to_bytes())
}

///|
/// Clears all the data in a Bloom filter, removing all keys
pub fn BloomFilter::clear_all(self : BloomFilter) -> BloomFilter {
  self.b.clear_all()
  return self
}

///|
/// estimate_false_positive_rate returns, for a BloomFilter of m bits
/// and k hash functions, an estimation of the false positive rate when
///	storing n entries. This is an empirical, relatively slow test using 
/// integers as keys. This function is useful to validate the implementation.
pub fn estimate_false_positive_rate(m : Int, k : Int, n : Int) -> Double {
  let rounds = 100000
  let bloom = BloomFilter::new(m, k)
  for i in 0..<n {
    let _ = bloom.add(i.to_le_bytes())

  }
  let mut count = 0
  for i in 0..<rounds {
    if bloom.check((n + i).to_le_bytes()) {
      count += 1
    }
  }
  count.to_double() / rounds.to_double()
}

///| Approximating the number of items
/// https://en.wikipedia.org/wiki/Bloom_filter#Approximating_the_number_of_items_in_a_Bloom_filter
pub fn BloomFilter::approximated_size(self : BloomFilter) -> Int {
  let x = self.b.count_ones().to_double()
  let m = self.get_cap().to_double()
  let k = self.get_k().to_double()
  let size : Double = -1 * m / k * @math.ln(1 - x / m)
  (size + 0.5).floor().to_int()
}

///|
/// Serialize from BloomFilter to Bytes 
pub fn BloomFilter::marshal_bytes(self : BloomFilter) -> Bytes {
  let buf : @buffer.T = @buffer.new()
  buf.write_int_le(self.m)
  buf.write_int_le(self.k)
  buf.write_bytes(self.b.marshal_bytes())
  buf.to_bytes()
}

///|
/// Serialize from Bytes to BloomFilter
pub fn BloomFilter::unmarshal_bytes(bytes : Bytes) -> BloomFilter {
  let m = bytes[0:4].to_int_le()
  let k = bytes[4:8].to_int_le()
  let bitvec = BitVector::unmarshal_bytes(bytes[8:].to_bytes())
  { m, k, b: bitvec }
}

///|

///| Equal tests for the equality of two Bloom filters
pub fn BloomFilter::equal(self : BloomFilter, other : BloomFilter) -> Bool {
  return self.m == other.m && self.k == other.k && self.b.equal(other.b)
}

///|

///| locations returns a list of hash locations representing a data item.
pub fn locations(data : Bytes, k : Int) -> Array[UInt64] {
  let locs = Array::make(k, 0UL)
  // calculate locations
  let hash256 = base_hashes(data)
  for i in 0..<k {
    locs[i] = location(hash256, i)
  }
  return locs
}

///|
fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}
