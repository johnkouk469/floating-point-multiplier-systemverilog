// Drives the six DUT instances (one per rounding mode) with the same stimulus as
// src/fp_mult_tb.sv (100000 random pairs, then all 10 x 10 corner cases) and writes
// every input/output set to random.txt as: round_index a b z status (hex).
// check_ref.sv then compares z with the course's reference function.
`timescale 1ns/1ns
`include "fp_mult_top.sv"

module random_tb ();
bit clk, rst;
bit [31:0] a, b;
bit [31:0] z [0:5];
bit [7:0] status [0:5];
int fd;
int n;

typedef enum { neg_nan, pos_nan, neg_inf, pos_inf, neg_norm, pos_norm, neg_denorm, pos_denrom, neg_zero, pos_zero } corner_cases_t;
corner_cases_t case_a, case_b;

function [31:0] corner_case_num (corner_cases_t corner_case);
    logic [31:0] num;
    unique case(corner_case)
        neg_nan: num = 32'hffa2d739;
        pos_nan: num = 32'h7fe091a5;
        neg_inf: num = 32'hff800000;
        pos_inf: num = 32'h7f800000;
        neg_norm: num = 32'h79422167;
        pos_norm: num = 32'hc61960c8;
        neg_denorm: num = 32'h806b90e2;
        pos_denrom: num = 32'h00748b0c;
        neg_zero: num = 32'h80000000;
        pos_zero: num = '0;
    endcase
    return num;
endfunction

fp_mult_top #(.round("IEEE_near")) DUT_IEEE_near (.*, .z(z[0]), .status(status[0]));
fp_mult_top #(.round("IEEE_zero")) DUT_IEEE_zero (.*, .z(z[1]), .status(status[1]));
fp_mult_top #(.round("IEEE_pinf")) DUT_IEEE_pinf (.*, .z(z[2]), .status(status[2]));
fp_mult_top #(.round("IEEE_ninf")) DUT_IEEE_ninf (.*, .z(z[3]), .status(status[3]));
fp_mult_top #(.round("near_up")) DUT_near_up (.*, .z(z[4]), .status(status[4]));
fp_mult_top #(.round("away_zero")) DUT_away_zero (.*, .z(z[5]), .status(status[5]));

task automatic dump();
    for (int r = 0; r < 6; r++) $fdisplay(fd, "%0d %h %h %h %h", r, a, b, z[r], status[r]);
endtask

initial begin
    fd = $fopen("random.txt", "w");
    clk = 0; rst = 1;
    #15 rst = 0;
    #5;
    for (n = 0; n < 100000; n++) begin
        a = $urandom();
        b = $urandom();
        #40 dump();
        #20;
    end
    case_a = case_a.first;
    do begin
        case_b = case_b.first;
        a = corner_case_num(case_a);
        do begin
            b = corner_case_num(case_b);
            #40 dump();
            case_b = case_b.next;
            #20;
        end while (case_b != case_b.first);
        case_a = case_a.next;
    end while (case_a != case_a.first);
    $fclose(fd);
    $finish;
end

always #10 clk = ~clk;
endmodule
