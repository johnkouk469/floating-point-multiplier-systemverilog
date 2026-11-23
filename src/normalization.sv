module normalize_mult (
    input logic [47:0] P, 
    input logic [9:0] added_exponent,
    output logic [22:0] normalized_mantissa, 
    output logic [9:0] normalized_exponent, 
    output logic sticky_bit, guard_bit
);

always_comb begin
    if (P[47]) begin
        normalized_exponent = added_exponent + 1;
        normalized_mantissa = P[46:24];
        guard_bit = P[23];
        sticky_bit = |P[22:0];
    end else begin
        normalized_exponent = added_exponent;
        normalized_mantissa = P[45:23];
        guard_bit = P[22];
        sticky_bit = |P[21:0];
    end
end

endmodule