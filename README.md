MoonBit Bloom Filter
-------------
This bloom filter library inspired by Go's [bloom](https://pkg.go.dev/github.com/bits-and-blooms/bloom/v3) package.

A Bloom filter is a concise/compressed representation of a set, where the main requirement is to make membership queries; _i.e._, whether an item is a member of a set. A Bloom filter will always correctly report the presence of an element in the set when the element is indeed present. A Bloom filter can use much less storage than the original set, but it allows for some 'false positives': it may sometimes report that an element is in the set whereas it is not.

When you construct, you need to know how many elements you have (the desired capacity), and what is the desired false positive rate you are willing to tolerate. A common false-positive rate is 1%. The lower the false-positive rate, the more memory you are going to require. Similarly, the higher the capacity, the more memory you will use. You may construct the Bloom filter capable of receiving 1 million elements with a false-positive rate of 1% in the following manner. 

```moonbit
let filter = new_with_estimates(1000000, 0.01)
```
You should call `new_with_estimates` conservatively: if you specify a number of elements that it is
too small, the false-positive bound might be exceeded. A Bloom filter is not a dynamic data structure: you must know ahead of time what your desired capacity is.

Our implementation accepts keys for setting and testing as `Bytes` or `String`. Thus, to add a string item, `"Hello"`:

```MoonBit
filter.add_string("Hello")
```

To check if `"Hello"` is in bloom:

```MoonBit
filter.check_string("Hello")
```

For numerical data:

```MoonBit
filter.add((100).to_le_bytes())
filter.check((100).to_le_bytes())
```

## Installation

Add chaijie2018/bloom to your dependencies:
```bash
moon update
moon add chaijie2018/bloom
```

## Verifying the False Positive Rate

Sometimes, the actual false positive rate may differ (slightly) from the theoretical false positive rate. We have a function to estimate the false positive rate of a Bloom filter with _m_ bits and _k_ hashing functions for a set of size _n_:

```MoonBit
if estimate_false_positive_rate(20*n, 5, n) > 0.001
```

You can use it to validate the computed m, k parameters:

```MoonBit
let (m, k) = estimate_parameters(n, fp)
let actual_fp_rate = estimate_false_positive_rate(m, k, n)
```

or

```MoonBit
let filter = new_with_estimates(n, fp)
let actual_fp_rate = estimate_false_positive_rate(f.m, f.k, n)
```

You would expect `actual_fp_rate` to be close to the desired false-positive rate `fp` in these cases.

The `estimate_false_positive_rate` function creates a temporary Bloom filter. It is also relatively expensive and only meant for validation.

## Design

A Bloom filter has two parameters: _m_, the number of bits used in storage, and _k_, the number of hashing functions on elements of the set. (The actual hashing functions are important, too, but this is not a parameter for this implementation). A Bloom filter is backed by a BitVector; a key is represented in the filter by setting the bits at each value of the hashing functions (modulo _m_). Set membership is done by _checking_ whether the bits at each value of the hashing functions (again, modulo _m_) are set. If so, the item is in the set. If the item is actually in the set, a Bloom filter will never fail (the true positive rate is 1.0); but it is susceptible to false positives. The art is to choose _k_ and _m_ correctly.

In this implementation, the hashing functions used is murmurhash, a non-cryptographic hashing function.

Given the particular hashing scheme, it's best to be empirical about this. Note that estimating the false positive rate will clear the Bloom filter.

## Contributing

If you wish to contribute to this project, please branch and issue a pull request against master ("[GitHub bloom](https://github.com/chaijie2018/bloom)")
