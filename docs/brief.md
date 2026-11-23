# Low-Level HW Digital Systems II: Floating-Point Multiplier

> The coursework brief as issued by the course staff (2023 lab manual and coursework). The text, tables and figures belong to the course staff; only this Markdown conversion is new. Sections on installing the simulator, the worked example, the deliverables and the marks are left out, and the figures (block diagrams and number line) are not reproduced. The report that answers it: [report.md](report.md).

The coursework is to design, in SystemVerilog, a single-precision floating-point multiplier, to test it with a testbench for all six rounding modes, and to verify its status flags with SystemVerilog Assertions (SVA).

## Floating point representation

All floating-point numbers consist of three parts:

1. A sign: it indicates whether the number is positive (sign = 0) or negative (sign = 1).
2. An exponent: this is the power of 2 (binary) that the mantissa is multiplied with to get the actual value.
3. A mantissa/fraction: the "fractional" portion of the number. There is an implied leading 1.

The sizes of the exponent and mantissa differ with the precision used. For the module under design only the single precision is used, which has an 8-bit exponent and a 23-bit mantissa (IEEE 754, 32 bits: 1 sign bit, 8 exponent bits $E$, 23 mantissa bits $M$).

The actual value of a single-precision number is

$$
N = (-1)^{S} \cdot 2^{E-127} \cdot (1.M), \qquad 0 < E < 255 .
$$

The exponent is always reduced by a bias, which here is 127. Based on the values of the three parts, the numbers fall into the categories below. In order on the number line: -NaNs, -Inf, -Normals, -Denormals, -Zero, +Zero, +Denormals, +Normals, +Inf, +NaNs.

Table I lists the pairing between each category and its representation, regardless of the precision. A 0 exponent and 0 mantissa represent positive or negative zero, depending on the sign. An exponent with all bits equal to 1 and a mantissa equal to 0 represent positive or negative infinity, depending on the sign. All numbers whose exponent bits are all 1 but whose mantissa has at least one bit equal to 1 are considered NaNs (there are multiple representations of a NaN). A denormal is a number whose exponent bits are all 0 and whose mantissa has at least one bit equal to 1. Most of the time, as well as in this case, denormals are considered equal to zero. All other numbers are normals and represent a value according to the formula above.

| Sign | Exponent (exp) | Significand (sig) | Value | Short name |
|---|---|---|---|---|
| $s$ | 0 | 0 | $(-1)^s  0$ | ±Zero |
| $s$ | 111...111 | 0 | $(-1)^s  \infty$ | ±Inf |
| $s$ | 111...111 | $0 < \mathrm{sig}$ | Not a Number | NaN |
| $s$ | 0 | $0 < \mathrm{sig}$ | $(-1)^s  2^{1-\mathrm{bias}}  0.\mathrm{sig}$ | Denormal |
| $s$ | $0 < \mathrm{exp} < 111...111$ | sig | $(-1)^s  2^{\mathrm{exp}-\mathrm{bias}}  1.\mathrm{sig}$ | Normal |

Table I: Special values for floating-point numbers. $s$ denotes the sign, sig the mantissa and exp the exponent. The bias is 127 for single precision.

Table II lists further special numbers. MinNorm and MaxNorm are the lower and upper bounds of the positive and negative normal numbers; MinDenorm and MaxDenorm are the lower and upper bounds of the denormals.

| Sign | Exponent | Significand | Value | Short name |
|---|---|---|---|---|
| $s$ | 1 | 0 | $(-1)^s  2^{1-\mathrm{bias}}$ | ±MinNorm |
| $s$ | 111...110 | 111...111 | $(-1)^s  2^{\mathrm{bias}}  (2 - 2^{-w})$ | ±MaxNorm |
| $s$ | 0 | 1 | $(-1)^s  2^{1-\mathrm{bias}-w}$ | ±MinDenorm |
| $s$ | 0 | 111...111 | $(-1)^s  2^{1-\mathrm{bias}}  (1 - 2^{-w})$ | ±MaxDenorm |

Table II: The upper and lower bounds of the normal and denormal numbers. $s$ denotes the sign, $w$ (sig_width) the mantissa width, and the bias is 127 for single precision.

## Describing the floating-point multiplier

The first task is to write a floating-point multiplier in SystemVerilog. The multiplier consists of four modules: the **main module**, the **normalization module**, the **rounding module** and the **exception module**. A wrapper module (`fp_mult_top`) is given and must be used as the top level for the other four modules.

### Main module

The main module has two inputs, two outputs and a rounding parameter `round` that controls the rounding and exception handling modules. The two inputs (`a`, `b`) and the output (`z`) of the multiplication are 32 bits long (single precision). The `status` output is 8 bits long; each bit has a different meaning, given in Table III. The wrapper contains input registers (for `a` and `b`) in front of the main module and output registers (for `z` and `status`) behind it.

The main module consists of the following seven stages, in this order:

1. Floating-point number sign calculation
2. Exponent addition
3. Exponent subtraction of the bias
4. Mantissa multiplication (including the leading ones)
5. Truncation and normalization
6. Rounding
7. Exception handling

| Bit | Flag | Description |
|---|---|---|
| 0 | Zero | $z = \pm\mathrm{Zero}$ |
| 1 | Infinity | $z = \pm\mathrm{Inf}$ |
| 2 | Invalid | $F = \mathrm{NaN}$ |
| 3 | Tiny | $\lvert F\rvert \neq \mathrm{Zero/Inf/NaN}$ and $\lvert F\rvert < \mathrm{MinNorm}$ |
| 4 | Huge | $\lvert F\rvert \neq \pm\mathrm{Inf/NaN}$ and $\lvert F\rvert > \mathrm{MaxNorm}$ |
| 5 | Inexact | $\lvert F\rvert \neq \mathrm{Zero/Inf/NaN}$ and $F \neq z$ |
| 6 | Unused | Reserved to 0 |
| 7 | Div by 0 | Division by zero, reserved to 0 otherwise |

Table III: Description of each bit of the output status flag. Warning: $z$ is the component's output, whereas $F$ is the calculated result before it gets rounded to $z$.

### Normalization module

The normalization module normalizes the mantissa of the floating-point number and finds the guard and sticky bits. Normalization is the act of shifting the binary point in order to leave one non-zero binary digit before the binary point while changing the exponent accordingly.

The inputs of the module are the 48-bit multiplication result `P` and the 10-bit sum of the exponents minus the bias. The outputs are the sticky and guard bits, the 23-bit normalized mantissa and the 10-bit normalized exponent.

The increment of the exponent by one, the normalized mantissa and the guard and sticky bits depend on the value of the MSB of the mantissa multiplication result `P`. The binary point is between the bits `P[46]` and `P[45]`. If the MSB is 1, the number before the binary point is `10` or `11`; the MSB is then considered the leading one, so the binary point has to be shifted to the left by one and the exponent changes. If the MSB is 0, the number before the binary point is `01`, so the binary point is not shifted and the exponent stays the same; `P[46]` is the leading one in this case.

The sticky bit is the OR-reduced result of the remaining bits of the 48-bit mantissa. (The normalized mantissa does not include the leading one.)

### Rounding module

The rounding module rounds the post-normalization mantissa based on the `round` parameter. The possible values of the parameter are in Table IV.

The first input of the module is the 24-bit mantissa, which consists of the leading one and the 23-bit output of the normalization module. The other inputs are the guard bit and the sticky bit, and the calculated sign from the first stage of the main module. The outputs are a 25-bit result (23 bits plus 2 more bits for a possible overflow) and a 1-bit `inexact` signal, which shows whether the result of the mantissa multiplication is exact. The multiplication of the two mantissas gives an exact number if and only if both the guard and sticky bits are 0.

The output `result` depends on the `round` parameter. Considering the signals `inexact` and `sign`, Table IV and the `round` parameter, create a case that gives the appropriate result value for each value of `round`. The result is either the same 24-bit mantissa as the input or the 24-bit mantissa increased by one. If `round` is invalid (default case), the module must return the value of the IEEE_near rounding in `result`.

| Name | Value | Description |
|---|---|---|
| round | IEEE_near | IEEE round to nearest, even. Round to the nearest representable value; if both are equally near, output the result with an even significand. |
| | IEEE_zero | IEEE round towards zero. |
| | IEEE_pinf | IEEE round to +Infinity. |
| | IEEE_ninf | IEEE round to -Infinity. |
| | near_up | Round to the nearest representable value; if both are equally near, output the result closer to +Infinity. |
| | away_zero | Round away from zero. |

Table IV: Possible values for the parameter `round` of the main module and their description.

After the rounding, if the MSB of the 25-bit resulting mantissa is 1, the mantissa has to be shifted right by one bit and the post-normalization exponent increased by one (post-rounding normalization); otherwise both stay the same.

The final 24-bit mantissa is called the post-rounding mantissa (warning: it includes the leading one) and the 10-bit exponent is called the post-rounding exponent. Together they form an early version of the output `z`, called `z_calc`, which is used by the exception handling module.

### Exception handling module

The exception handling module handles extreme (corner) cases, such as the multiplication of two big numbers that leads to overflow, or the multiplication of infinities.

The inputs of the module are the initial 32-bit values (`a`, `b`), the 32-bit value calculated after the rounding (`z_calc`), and the `overflow`, `underflow` and `inexact` bits. The parameter `round` is also an input of this module.

The 1-bit signals `overflow` and `underflow` are calculated inside the main module after the rounding stage. Overflow occurs if the post-rounding exponent is bigger than the maximum possible exponent (without considering the two MSBs). Underflow occurs if the normalized exponent is smaller than the minimum possible exponent.

The outputs are the 32-bit `z`, which is connected to the output of the main module, and six 1-bit signals (`zero_f`, `inf_f`, `nan_f`, `tiny_f`, `huge_f`, `inexact_f`) that correspond to 6 of the 8 status bits. These bits are combined after the exception handling in the main module to create the `status` output.

Inside the module, create an enumerated typedef called `interp_t` (interpreter), two helper functions that use it, and a case block.

The enumeration `interp_t` contains all the possible unsigned groups a floating-point number can belong to (see the number line above), as well as the minNormal and maxNormal cases: `ZERO`, `INF`, `NORM`, `MIN_NORM` and `MAX_NORM`. The groups NaN and denormal are not added, since they are considered infinities and zeroes, respectively.

The first function, `num_interp` (numeric interpretation), returns a value of `interp_t` based on the value of a 32-bit input logic signal. Denormals are considered zeroes and NaNs infinities at this point. `MIN_NORM` and `MAX_NORM` do not need to be included in the function.

The second function, `z_num`, does the opposite: it takes a value of `interp_t` and returns the unsigned (31-bit) version of the value. For example, for `ZERO` it returns 31 zero bits. The `NORM` value does not need to be included in this function.

Finally, inside an `always_comb` block, initialize the status bit outputs of the module to zero. Then, based on Table V, define the value of `z` and activate the necessary status bits. The sign of `z_calc` and the functions defined above help here.

| A (sA.expA.sigA) | B (sB.expB.sigB) | Infinitely precise result (F) |
|---|---|---|
| ±Zero | ±Zero | $(-1)^{sA+sB}$ Zero |
| ±Zero | ±Norm | $(-1)^{sA+sB}$ Zero |
| ±Zero | ±Inf | +Inf |
| ±Inf | ±Inf | $(-1)^{sA+sB}$ Inf |
| ±Inf | ±Norm | $(-1)^{sA+sB}$ Inf |
| ±Inf | ±Zero | +Inf |
| ±Norm | ±Zero | $(-1)^{sA+sB}$ Zero |
| ±Norm | ±Inf | $(-1)^{sA+sB}$ Inf |

Table V: Possible corner-case combinations for the signals a and b. The combination Norm x Norm is not included in the table.

For the Normal x Normal combination, check whether there is overflow or underflow. If there is an overflow, then, based on the `round` parameter and the sign of `z_calc`, round the output either to the maxNormal number or to infinity. Likewise, if there is an underflow, then, based on the same criteria, round the output either to minNormal or to zero. If there is neither overflow nor underflow, `z` should be equal to `z_calc` and `inexact_f` should be equal to `inexact`.

## Testbench

The second task is to write a SystemVerilog testbench that tests the correctness of the modules for all six possible roundings. The testbench has two parts: in the first, the multiplication result is checked for random input values; in the second, the corner cases are checked. The clock period is 20 ns.

For the first part, the `$urandom()` function can be used to produce random values for the inputs `a` and `b`. The result `z` of the wrapper must be compared with the actual result of the multiplication, and an error displayed in case of a mismatch. To produce this reference result, the function `multiplication`, given along with the wrapper, can be used. The number of random values explored is up to the student.

For the second part, the correctness of the multiplication has to be shown for all the possible corner cases of the inputs `a` and `b`, as defined on the number line. It is advised to create a function that matches each corner case to a string, which helps (for example, the binary pattern of positive infinity matches the string `pos_inf`). As corner cases for each of `a` and `b`, the following 10 are chosen:

- 1 specific negative and 1 specific positive NaN
- negative and positive infinity
- 1 specific negative and 1 specific positive normal
- 1 specific negative and 1 specific positive denormal
- negative and positive zero

All the possible combinations of the corner cases between `a` and `b` (10 x 10 = 100 combinations) have to be tested, checking for each that the result of the wrapper is equal to the result of the `multiplication` function.

## SystemVerilog assertions

From Table III, some of the status bits cannot (and should not) be asserted at the same time. The first part of the third task is to write all possible immediate assertions, each testing that two status bits are not 1 together.

For the second part, five concurrent assertions are to be written. They verify the following, at each positive clock edge:

- If the `zero` status bit is 1, then in the same cycle all the bits of the exponent of `z` must be 0.
- If the `inf` status bit is 1, then in the same cycle all the bits of the exponent of `z` must be 1.
- If the `nan` status bit is 1, then 2 cycles before, all the bits of the exponent of `a` must be 0 and the bits of the exponent of `b` must be 1, or the opposite.
- If the `huge` status bit is 1, then in the same cycle all the bits of the exponent of `z` must be 1, or the maxNormal case is encountered.
- If the `tiny` status bit is 1, then in the same cycle all the bits of the exponent of `z` must be 0, or the minNormal case is encountered.

The two parts are implemented in two different modules called `test_status_bits` and `test_status_z_combinations`, respectively, and bound to the wrapper module.
