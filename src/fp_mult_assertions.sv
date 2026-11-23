`include "test_status_bits.sv"
`include "test_status_z_combinations.sv"
module fp_mult_assertions (
    input logic clk, rst,
    input logic [31:0] a, b, z,
    input logic [7:0] status    
);


test_status_bits status_bits (.*);
test_status_z_combinations status_z_combinations (.*);

endmodule