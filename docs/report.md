# Coursework for Low Level Hardware Digital Systems 2

14/7/2023

The coursework brief: [brief.md](brief.md).

This document is my report for the coursework of the course Low Level Hardware Digital Systems 2. In the coursework I implemented a single-precision floating-point multiplier based on the IEEE 754 standard.

## Description of the testbench

I define a `timescale` of 1ns with a precision of 1ns, which is used for the delays and also for the clock of period 20ns (signal `clk`).

I instantiate the module `fp_mult_top` once for each different type of rounding. I use the same 32-bit signals `a`, `b` as inputs for all the instantiations, so that each time I change the values of `a` and `b`, the instantiations take the product of their multiplication for all the types of rounding. For the outputs `z` and `status` I have six 32-bit `z` and six 8-bit `status`, and I give one of each to every instantiation.

I define an array `round_parameters` of strings that contains the name of each type of rounding, and the indices of the array correspond to the indices of the six `z` and the six `status` signals of 32 and 8 bits. So `round_parameters[3]` contains the string "IEEE_ninf", and `z[3]`, `status[3]` are the outputs of the instantiation that uses the rounding "IEEE_ninf". I use the array `round_parameters` inside an `always_comb` procedural block that calculates the output of the function `multiplication`, which is given to us, for all the roundings (iterating over `round_parameters`), and I store the results in the array `z_func`, which has six 32-bit signals, exactly like `z`. So with every change of `a`, `b`, `z` contains their product from the six instantiations and `z_func` contains their product from the function `multiplication` for all the roundings. For the design of `fp_mult_top` to be correct, `z` and `z_func` must therefore be identical for every `a`, `b`.

I do two checks to see whether `z` and `z_func` are identical: one where I give random values to `a` and `b`, and one that checks all the corner cases. For each of the two checks I define an integer of type `int`, `iteration_rand_mult` and `iteration_corner_case_mult`. These integers are initialized with zero and are increased by one 40ns after the change of `a`, `b` (which corresponds to two clock cycles) during the corresponding check. Each of them is in the sensitivity list of an `always` procedural block in which I check whether `z` is identical to `z_func`. If they are not identical, a message is printed to the console informing about the failure, with information that can help in debugging the modules.

For the check of the corner cases I define an enumerator `corner_cases_t` with all the possible cases and a function `corner_case_num` that takes the enumerator as its argument and returns the number of the corresponding case.

The values of `a`, `b` for the two checks are assigned inside an `initial` block using a `do while` loop.

## Verification of correct operation and simulation

The rounding module follows Table IV of the [brief](brief.md): the `inexact` bit is taken into account, so an exact product is never rounded; in the case of "IEEE_near" and "near_up", when the two nearest representable numbers are equally near, the result is the one with an even mantissa and the one closer to +Infinity, respectively; and the sticky bit is the OR reduction of all the discarded bits.

The results that the instantiations of `fp_mult_top` produce are identical to those of the function `multiplication`. Running the check for 100,000 random values of `a`, `b` gave no case in which the results were not identical for all the roundings. The same held for the 100 combinations of corner cases. The directory [tests](../tests) repeats this comparison and adds directed cases that random values practically never reach: exact products, exact ties between two representable numbers, and inexact products whose discarded bits contain an even number of ones.

In the console only messages about a difference between the results of the instantiations and the function `multiplication` are printed, and for every combination `a`, `b` one row of "-" is printed. Before the two checks the messages "START simulating multiplication of random numbers" and "START simulation multiplication of corner cases" are printed.

The following waveform shows three multiplications through `fp_mult_top` with the rounding "IEEE_near", together with the signals inside the main module: the product of the two numbers π and e; a multiplication whose result lies exactly halfway between two representable numbers (the guard bit is 1, the sticky bit is 0 and the result is rounded to the even neighbour `3FC00004`); and a multiplication that overflows (`status` equal to `12`, which means that the `inf` and `huge` bits are set). The input registers and the output registers of `fp_mult_top` delay the result by two clock cycles.

![Waveform of three multiplications with rounding IEEE_near: the signals a, b, the registered a1, b1, the multiplied and normalized mantissa, the guard, sticky and inexact bits, the rounded mantissa, the post-rounding exponent, overflow, z_calc, and the registered outputs z and status.](figures/floating-point-datapath.png)

All the immediate and concurrent assertions run normally and successfully, doing the checks that were requested. In a run of the testbench the transcript shows only PASS messages for them, for all six instantiations.

## Comments and observations

For the check of the overflow I look at whether the two MSBs of `post_rounding_exponent` are 01, which means that during the addition of the exponents the maximum allowed value, 255, was exceeded.

Correspondingly, for the check of the underflow I look at whether the two MSBs of `normalized_exponent` are 11. The reason I look at whether they are 11 has to do with the representation of negative numbers. The most extreme case is when both the exponent of `a` and the exponent of `b` are zero, where `added_exponent` is equal to -127. The value -127 is represented as 1110000001 and -1 as 1111111111. So when the exponent we calculate comes out negative, the two MSBs of `normalized_exponent` will be 11.

In the exception module, in the case where we multiply two normal numbers, besides the checks for overflow and underflow I have added two more, in which I check whether the exponent of `z_calc` is 255 or 0. These extra checks exist to handle the borderline cases where `post_rounding_exponent` has been calculated to be exactly 255 or zero without there being overflow or underflow, that is, the two MSBs will be equal to zero.
