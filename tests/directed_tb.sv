// Directed cases that random stimulus practically never reaches: exact products, exact
// ties between two floats, and inexact products whose discarded bits hold an even number
// of ones. Writes directed.txt in the same format as random_tb.sv.
`timescale 1ns/1ns
`include "fp_mult_top.sv"

module directed_tb ();
bit clk, rst;
bit [31:0] a, b;
bit [31:0] z [0:5];
bit [7:0] status [0:5];
int fd;

fp_mult_top #(.round("IEEE_near")) DUT_IEEE_near (.*, .z(z[0]), .status(status[0]));
fp_mult_top #(.round("IEEE_zero")) DUT_IEEE_zero (.*, .z(z[1]), .status(status[1]));
fp_mult_top #(.round("IEEE_pinf")) DUT_IEEE_pinf (.*, .z(z[2]), .status(status[2]));
fp_mult_top #(.round("IEEE_ninf")) DUT_IEEE_ninf (.*, .z(z[3]), .status(status[3]));
fp_mult_top #(.round("near_up")) DUT_near_up (.*, .z(z[4]), .status(status[4]));
fp_mult_top #(.round("away_zero")) DUT_away_zero (.*, .z(z[5]), .status(status[5]));

task automatic dump();
    for (int r = 0; r < 6; r++) $fdisplay(fd, "%0d %h %h %h %h", r, a, b, z[r], status[r]);
endtask

bit [31:0] pa [0:19];
bit [31:0] pb [0:19];
// Expected status flags for the special cases: mode 0 = not checked, 1 = checked for IEEE_near
// only, 2 = checked for all six roundings.
bit [7:0] exp_st [0:19];
int mode [0:19];

initial begin
    // exact products
    pa[0]  = 32'h3f800000; pb[0]  = 32'h3f800000; // 1.0 * 1.0
    pa[1]  = 32'h3fc00000; pb[1]  = 32'h40000000; // 1.5 * 2.0
    pa[2]  = 32'h40400000; pb[2]  = 32'h40400000; // 3.0 * 3.0
    pa[3]  = 32'hbf800000; pb[3]  = 32'h3fc00000; // -1.0 * 1.5
    // exact ties (guard bit 1, everything below it 0)
    pa[4]  = 32'h3f800003; pb[4]  = 32'h3fc00000; // 4.5 ulp, even neighbour below
    pa[5]  = 32'h3f800001; pb[5]  = 32'h3fc00000; // 1.5 ulp, even neighbour above
    pa[6]  = 32'hbf800003; pb[6]  = 32'h3fc00000; // negative tie
    // inexact products, even number of ones below the guard bit
    pa[7]  = 32'h3f800005; pb[7]  = 32'h3f800005;
    pa[8]  = 32'h3f800007; pb[8]  = 32'h3f800009;
    pa[9]  = 32'h3f80000b; pb[9]  = 32'h3f800003;
    pa[10] = 32'h3fa5a5a5; pb[10] = 32'h3f9a5a5a;
    pa[11] = 32'h3fffffff; pb[11] = 32'h3fffffff;
    // status flags with zero or denormal operands: only "zero" (a zero result of a zero operand
    // is not a tiny result)
    pa[12] = 32'h00000000; pb[12] = 32'h00000000; exp_st[12] = 8'h01; mode[12] = 2; // 0 * 0
    pa[13] = 32'h00000000; pb[13] = 32'h00748b0c; exp_st[13] = 8'h01; mode[13] = 2; // 0 * denormal
    pa[14] = 32'h806b90e2; pb[14] = 32'h00748b0c; exp_st[14] = 8'h01; mode[14] = 2; // denormal * denormal
    // two small normals whose product underflows: zero and tiny together (IEEE_near)
    pa[15] = 32'h0d800001; pb[15] = 32'h0d800001; exp_st[15] = 8'h09; mode[15] = 1;
    // two large normals whose product overflows: infinity and huge together (IEEE_near)
    pa[16] = 32'h7f000000; pb[16] = 32'h7f000000; exp_st[16] = 8'h12; mode[16] = 1;
    // status flags with infinity or NaN operands: only "infinity" (the result is not a huge
    // finite number)
    pa[17] = 32'h7f800000; pb[17] = 32'h7f800000; exp_st[17] = 8'h02; mode[17] = 2; // Inf * Inf
    pa[18] = 32'h7f800000; pb[18] = 32'h79422167; exp_st[18] = 8'h02; mode[18] = 2; // Inf * normal
    pa[19] = 32'h7fe091a5; pb[19] = 32'hff800000; exp_st[19] = 8'h02; mode[19] = 2; // NaN * Inf
    fd = $fopen("directed.txt", "w");
    clk = 0; rst = 1;
    #15 rst = 0;
    #5;
    for (int i = 0; i < 20; i++) begin
        a = pa[i]; b = pb[i];
        #40 dump();
        if (mode[i] != 0)
            for (int r = 0; r < ((mode[i] == 2) ? 6 : 1); r++)
                if (status[r] !== exp_st[i])
                    $display("STATUS FAIL round_index=%0d a=%h b=%h status=%h expected=%h", r, a, b, status[r], exp_st[i]);
        #20;
    end
    $fclose(fd);
    $finish;
end

always #10 clk = ~clk;
endmodule
