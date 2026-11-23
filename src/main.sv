`include "normalization.sv"
`include "rounding.sv"
`include "exception.sv"

module fp_mult #(parameter round = "IEEE_near") (
    input logic [31:0] a, b,
    output logic [31:0] z,
    output logic [7:0] status
);


typedef struct packed {
    logic sign;
    logic [7:0] exponent;
    logic [22:0] mantissa;
} floating_number;

floating_number num_a, num_b;

logic [47:0] multiplied_mantissa;
logic [9:0] added_exponent;
logic sign;

logic [9:0] normalized_exponent;
logic [22:0] normalized_mantissa;
logic sticky_bit, guard_bit;

logic [24:0] rounded_mantissa;
logic inexact;

logic [9:0] post_rounding_exponent;
logic [23:0] post_rounding_mantissa;

logic [31:0] z_calc;
logic overflow, underflow;

normalize_mult normalizer (.*, .P(multiplied_mantissa));
round_mult rounder(.*, .round(!(round inside {"IEEE_near", "IEEE_zero", "IEEE_pinf", "IEEE_ninf", "near_up", "away_zero"}) ? "IEEE_near" : round), .mantissa({1'b1, normalized_mantissa}), .result(rounded_mantissa));
exception_mult exception_handler(.*, .round(!(round inside {"IEEE_near", "IEEE_zero", "IEEE_pinf", "IEEE_ninf", "near_up", "away_zero"}) ? "IEEE_near" : round), .zero_f(status[0]), .inf_f(status[1]), .nan_f(status[2]), .tiny_f(status[3]), .huge_f(status[4]), .inexact_f(status[5]));

always_comb begin  
    num_a = a;
    num_b = b;

    // Calculate of the sign of product
    sign = num_a.sign ^ num_b.sign;

    // Multiply the mantissas
    multiplied_mantissa = {1'b1, num_a.mantissa} * {1'b1, num_b.mantissa};

    // Add the exponents
    added_exponent = num_a.exponent + num_b.exponent - 127;

    // Shift mantissa after rounding if needed
    if (rounded_mantissa[24] == 1) begin
        post_rounding_mantissa = rounded_mantissa >> 1;
        post_rounding_exponent = normalized_exponent + 1;
    end else begin
        post_rounding_mantissa = rounded_mantissa[23:0];
        post_rounding_exponent = normalized_exponent;
    end

    if (post_rounding_exponent[9:8] == 2'b01) overflow = 1; else overflow = 0;
    if (normalized_exponent[9:8] == 2'b11) underflow = 1; else underflow = 0;

    z_calc = {sign, post_rounding_exponent[7:0], post_rounding_mantissa[22:0]};

    status[7:6] = '0;
end

endmodule