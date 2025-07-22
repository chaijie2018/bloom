///|
test "check" {
  let filter = new_with_estimates(100, 0.001)
  let _ = filter.add("Hello".to_bytes()).add("MoonBit".to_bytes())
  assert_true(filter.check("Hello".to_bytes()))
  assert_true(filter.check("MoonBit".to_bytes()))
  assert_false(filter.check("C++".to_bytes()))
}

///|
test "check_or_add" {
  let filter1 = new_with_estimates(100, 0.001)
  let _ = filter1.add_string("Hello")
  assert_true(filter1.check_or_add_string("Hello"))
  assert_false(filter1.check_or_add_string("MoonBit"))
  assert_true(filter1.check_or_add_string("MoonBit"))
}

///| https://krisives.github.io/bloom-calculator/
test "estimate_parameters" {
  let (m, k) = estimate_parameters(10000, 0.01)
  inspect(m, content="95851")
  inspect(k, content="7")
}

///|
test "false_positive_rate" {
  let f = new_with_estimates(100, 0.01)
  let actual_fp_rate = estimate_false_positive_rate(f.m, f.k, 100)
  println(actual_fp_rate)
}

///|
test "approximated_size" {
  let filter = new_with_estimates(10000, 0.01)
  let _ = filter.add_string("MoonBit").add_string("is").add_string("awesome")
  let size = filter.approximated_size()
  assert_eq(size, 3)
  let size2 = filter.clear_all().approximated_size()
  assert_eq(size2, 0)
}

///|
test "equal" {
  let filter = new_with_estimates(100, 0.001)
  let _ = filter.add_string("MoonBit")
  let filter2 = new_with_estimates(100, 0.001)
  let _ = filter2.add_string("Moonbit")
  assert_false(filter.equal(filter2))
}

///|
test "merge" {
  let filter1 = new_with_estimates(100, 0.001)
  let _ = filter1.add_string("Hello")
  let filter2 = new_with_estimates(100, 0.001)
  let _ = filter2.add_string("MoonBit")
  let filter3 = new_with_estimates(100, 0.001)
  let _ = filter3.add_string("Hello").add_string("MoonBit")
  assert_true(filter3.equal(filter1.merge(filter2)))
  assert_true(filter3.equal(filter2.merge(filter1)))
}
