///|
test "new_constructor" {
  let bv = BitVector::new(64)
  assert_eq(bv.length, 64)
  assert_eq(bv.is_all_zeros(), true)
  assert_eq(bv.count_ones(), 0)
}

///|
test "ones_constructor" {
  let bv = BitVector::ones(64)
  assert_eq(bv.length, 64)
  assert_eq(bv.is_all_ones(), true)
  assert_eq(bv.count_zeros(), 0)
}

///|
test "from_ints_constructor" {
  let ints = [3UL, 7UL]
  let bv = BitVector::from_with_length(ints, 128)
  assert_eq(bv.get(0), true)
  assert_eq(bv.get(1), true)
  assert_eq(bv.get(2), false)
  assert_eq(bv.get(64), true)
  assert_eq(bv.get(65), true)
  assert_eq(bv.get(66), true)
}

///|
test "from_bools_constructor" {
  let bools = [true, false, true, true]
  let bv = BitVector::from_bools(bools)
  assert_eq(bv.length, 4)
  assert_eq(bv.get(0), true)
  assert_eq(bv.get(1), false)
  assert_eq(bv.get(2), true)
  assert_eq(bv.get(3), true)
}

///|
test "from_string_constructor" {
  let bv = BitVector::from_string("1010")
  assert_eq(bv.length, 4)
  assert_eq(bv.get(0), true)
  assert_eq(bv.get(1), false)
  assert_eq(bv.get(2), true)
  assert_eq(bv.get(3), false)
}

///|
test "get" {
  let bv = BitVector::from_string("101011")
  assert_eq(bv.get(0), true)
  assert_eq(bv.get(1), false)
  assert_eq(bv.get(5), true)
}

///|
test "set" {
  let bv = BitVector::new(5)
  bv.set(2)
  assert_eq(bv.get(2), true)
}

///|
test "clear" {
  let bv = BitVector::ones(5)
  bv.clear(2)
  assert_eq(bv.get(2), false)
}

///|
test "flip" {
  let bv = BitVector::from_string("10101")
  bv.flip(1)
  assert_eq(bv.get(1), true)
}

///|
test "flip_all" {
  let bv = BitVector::from_string("10101")
  bv.flip_all()
  assert_eq(bv.get(0), false)
  assert_eq(bv.get(1), true)
  assert_eq(bv.get(2), false)
  assert_eq(bv.get(3), true)
  assert_eq(bv.get(4), false)
}

///|
test "intersection" {
  let bv1 = BitVector::from_string("1010")
  let bv2 = BitVector::from_string("1100")
  let result = bv1.intersection(bv2)
  assert_eq(result.to_string(), "1000")
}

///|
test "union" {
  let bv1 = BitVector::from_string("1010")
  let bv2 = BitVector::from_string("1100")
  let result = bv1.union(bv2)
  assert_eq(result.to_string(), "1110")
}

///|
test "difference" {
  let bv1 = BitVector::from_string("1010")
  let bv2 = BitVector::from_string("1100")
  let result = bv1.difference(bv2)
  assert_eq(result.to_string(), "0110")
}

///|
test "count_ones" {
  let bv = BitVector::from_string("101010")
  assert_eq(bv.count_ones(), 3)
}

///|
test "count_zeros" {
  let bv = BitVector::from_string("101010")
  assert_eq(bv.count_zeros(), 3)
}

///|
test "find_first_set" {
  let bv1 = BitVector::from_string("001010")
  assert_eq(bv1.find_first_set(), 2)
  let bv2 = BitVector::new(5)
  assert_eq(bv2.find_first_set(), -1)
}

///|
test "to_string" {
  let bv = BitVector::from_string("101010")
  assert_eq(bv.to_string(), "101010")
}

///|
test "to_bools" {
  let bv = BitVector::from_string("1010")
  let bools = bv.to_bools()
  assert_eq(bools.length(), 4)
  assert_eq(bools[0], true)
  assert_eq(bools[1], false)
  assert_eq(bools[2], true)
  assert_eq(bools[3], false)
}

///|
test "is_all_zeros" {
  let bv1 = BitVector::new(100)
  assert_eq(bv1.is_all_zeros(), true)
  let bv2 = BitVector::from_string("0000100000")
  assert_eq(bv2.is_all_zeros(), false)
}

///|
test "is_all_ones" {
  let bv1 = BitVector::ones(100)
  assert_eq(bv1.is_all_ones(), true)
  let bv2 = BitVector::from_string("1111011111")
  assert_eq(bv2.is_all_ones(), false)
}

///|
test "equal" {
  let bv1 = BitVector::new(200)
  let bv2 = BitVector::new(200)
  assert_eq(bv1.data.length(), 4)
  assert_eq(bv1.equal(bv2), true)
  bv1.set(8)
  assert_eq(bv1.equal(bv2), false)
}

///|
test "trailing_zeros" {
  assert_eq(trailing_zeros(0), -1)
  assert_eq(trailing_zeros(1), 0)
  assert_eq(trailing_zeros(8), 3)
}

///|
test "small_bitvector" {
  let bv = BitVector::new(1)
  assert_eq(bv.get(0), false)
  bv.set(0)
  assert_eq(bv.get(0), true)
  assert_eq(bv.is_all_zeros(), false)
}

///|
test "chained_operations" {
  let bv1 = BitVector::from_string("1100")
  let bv2 = BitVector::from_string("1010")
  let bv3 = BitVector::from_string("0101")
  let combined = bv1.intersection(bv2).union(bv3)
  assert_eq(combined.to_string(), "1101")
}

///|
test "to_and_from_conversion" {
  let original = BitVector::from_string("10101100001111")
  let str = original.to_string()
  let from_str = BitVector::from_string(str)
  assert_eq(original.to_string(), from_str.to_string())
  let bools = original.to_bools()
  let from_bools = BitVector::from_bools(bools)
  assert_eq(original.to_string(), from_bools.to_string())
}

///|
test "find_first_set" {
  let bv = BitVector::new(200)
  assert_eq(bv.find_first_set(), -1)
  bv.set(64)
  assert_eq(bv.find_first_set(), 64)
  let bv2 = BitVector::ones(128)
  assert_eq(bv2.find_first_set(), 0)
}

///|
test "all_zero_and_all_one_logic" {
  let zeros = BitVector::new(128)
  let ones = BitVector::ones(128)
  let and_result = ones.intersection(zeros)
  assert_eq(and_result.count_ones(), 0)
  let or_result = ones.union(zeros)
  assert_eq(or_result.count_ones(), 128)
  let xor_result = ones.difference(zeros)
  assert_eq(xor_result.is_all_ones(), true)
}

///|
test "chained_set_clear_flip" {
  let bv = BitVector::new(16)
  for i in 0..<16 {
    if i % 2 == 0 {
      bv.set(i)
    }
  }
  for i in 0..<16 {
    if i % 2 == 0 {
      assert_eq(bv.get(i), true)
    } else {
      assert_eq(bv.get(i), false)
    }
  }
  bv.flip(4)
  bv.clear(5)
  assert_eq(bv.get(4), false)
  assert_eq(bv.get(5), false)
}

///|
test "bools_to_string_roundtrip" {
  let bools = [true, false, true, false, true]
  let bv = BitVector::from_bools(bools)
  let str = bv.to_string()
  assert_eq(str, "10101")
  let bv2 = BitVector::from_string(str)
  assert_eq(bv2.to_string(), "10101")
}

///|
test "serialization_roundtrip" {
  let original = BitVector::from_string("1100101011110000")
  let serialized = original.to_string()
  let deserialized = BitVector::from_string(serialized)
  assert_eq(original.to_string(), deserialized.to_string())
}
