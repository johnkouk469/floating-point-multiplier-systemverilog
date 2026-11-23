module test_status_z_combinations (
    input logic clk, rst,
    input logic [31:0] a, b, z,
    input logic [7:0] status    
);

sequence max_normal_case;
    z[30:0] == {{7{1'b1}}, 1'b0, {23{1'b1}}};
endsequence

sequence min_normal_case;
    z[30:0] == {{7{1'b0}}, 1'b1, {23{1'b0}}};
endsequence

sequence exponent_bits_ones;
    z[30:23] == '1;
endsequence

sequence exponent_bits_zeros;
    z[30:23] == '0;
endsequence

property zero;
    @(posedge clk) status[0] |-> exponent_bits_zeros;
endproperty

property infinite;
    @(posedge clk) status[1] |-> exponent_bits_ones;
endproperty

property nan;
    @(posedge clk) status[2] |-> ($past(a[30:23],2) == '0 and $past(b[30:23],2) == '1) or ($past(a[30:23],2) == '1 and $past(b[30:23],2) == '0);
endproperty

property tiny;
    @(posedge clk) status[3] |-> exponent_bits_zeros or min_normal_case;
endproperty;

property huge;
    @(posedge clk) status[4] |-> exponent_bits_ones or max_normal_case;
endproperty

assertZeroStatusBit: assert property (zero) $display($stime,,,"\t\t %m PASS");
else $display($stime,,,"\t\t %m FAIL"); 

assertInfiniteStatusBit: assert property (infinite) $display($stime,,,"\t\t %m PASS");
else $display($stime,,,"\t\t %m FAIL");

assertNaNStatusBit: assert property (nan) $display($stime,,,"\t\t %m PASS");
else $display($stime,,,"\t\t %m FAIL");

assertTinyStatusBit: assert property (tiny) $display($stime,,,"\t\t %m PASS");
else $display($stime,,,"\t\t %m FAIL"); 

assertHugeStatusBit: assert property (huge) $display($stime,,,"\t\t %m PASS");
else $display($stime,,,"\t\t %m FAIL"); 

endmodule