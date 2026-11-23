`timescale 1ns/1ns

`include "fp_mult_top.sv"
`include "fp_mult_assertions.sv"
`include "multiplication.sv"

module fp_mult_tb ();


bit clk, rst;
bit [31:0] a, b; 
bit [31:0] z [0:5];
bit [31:0] z_func [0:5];
bit [7:0] status [0:5];
int iteration_rand_mult;
int iteration_corner_case_mult;

typedef enum { neg_nan, pos_nan, neg_inf, pos_inf, neg_norm, pos_norm, neg_denorm, pos_denrom, neg_zero, pos_zero } corner_cases_t;
corner_cases_t case_a, case_b;

function [31:0] corner_case_num (corner_cases_t corner_case);
    logic [31:0] num;
    unique case(corner_case)
        neg_nan: num = 32'hffa2d739; //{1'b1, {8{1'b1}}, 23'h39A2D7};
        pos_nan: num = 32'h7fe091a5; //{0'b1, {8{1'b1}}, 23'h4F91E0};
        neg_inf: num = 32'hff800000; //{1'b1, {8{1'b1}}, {23{1'b0}}};
        pos_inf: num = 32'h7f800000; //{1'b0, {8{1'b1}}, {23{1'b0}}};
        neg_norm: num = 32'h79422167;
        pos_norm: num = 32'hc61960c8;
        neg_denorm: num = 32'h806b90e2; //{1'b1, {8{1'b0}}, 23'h689EB5};
        pos_denrom: num = 32'h00748b0c; //{{9{1'b0}}, 23'h748B0C};
        neg_zero: num = 32'h80000000; //{1'b1, {31{1'b0}}};
        pos_zero: num = '0;
    endcase
    return num;
endfunction

const string round_parameters [0:5] = {"IEEE_near", "IEEE_zero", "IEEE_pinf", "IEEE_ninf", "near_up", "away_zero"};

// Initalize a DUT for each one of the 6 possible roundings
fp_mult_top #(.round("IEEE_near")) DUT_IEEE_near (.*, .z(z[0]), .status(status[0]));
fp_mult_top #(.round("IEEE_zero")) DUT_IEEE_zero (.*, .z(z[1]), .status(status[1]));
fp_mult_top #(.round("IEEE_pinf")) DUT_IEEE_pinf (.*, .z(z[2]), .status(status[2]));
fp_mult_top #(.round("IEEE_ninf")) DUT_IEEE_ninf (.*, .z(z[3]), .status(status[3]));
fp_mult_top #(.round("near_up")) DUT_near_up (.*, .z(z[4]), .status(status[4]));
fp_mult_top #(.round("away_zero")) DUT_away_zero (.*, .z(z[5]), .status(status[5]));

bind fp_mult_top fp_mult_assertions dut_bound (.clk(clk), .rst(rst), .a(a), .b(b), .status(status), .z(z));

initial begin
    clk = 0;
    rst = 1;
    #15 rst = 0;
    #5 $display("START simulating multiplication of random numbers");
    iteration_rand_mult = 0;
    iteration_corner_case_mult = 0;
    do begin
        a = $urandom();
        b = $urandom();
        #40 iteration_rand_mult++;
        #20 $display("---------------------");
    end while (iteration_rand_mult < 100000);
    #20 $display("START simulation multiplication of corner cases");
    case_a = case_a.first;
    do begin
        case_b = case_b.first;
        a = corner_case_num(case_a);
        do begin
            b = corner_case_num(case_b);
            #40 case_b = case_b.next;
            iteration_corner_case_mult++;
            #20 $display("---------------------");
        end while (case_b != case_b.first);
        case_a = case_a.next;
    end while (case_a != case_a.first);
    #40 $finish(2);
end

always #10 clk = ~clk;

always_comb begin
    for (int rounding = 0; rounding < 6; rounding++) begin
        z_func[rounding] = multiplication(round_parameters[rounding], a, b);
    end
end

always @(iteration_rand_mult) begin
    for (int rounding = 0; rounding < 6; rounding++) begin
        if(z[rounding] != z_func[rounding]) begin
            $display($stime,,,"\t\t %m FAIL: The DUT failed to calculate the product of the multiplication correctly for inputs:");
            $display("a: %h", a);
            $display("b: %h", b);
            $display("round: %s", round_parameters[rounding]);
            $display("The product is:    %h with sign: %h, exponent: %h, mantissa: %h", z[rounding], z[rounding][31], z[rounding][30:23], z[rounding][22:0]);
            $display("When it should be: %h with sign: %h, exponent: %h, mantissa: %h", z_func[rounding], z_func[rounding][31], z_func[rounding][30:23], z_func[rounding][22:0]);
        end
    end
end

always @(iteration_corner_case_mult) begin
    for (int rounding = 0; rounding < 6; rounding++) begin
        if(z[rounding] != z_func[rounding]) begin
            $display($stime,,,"\t\t %m FAIL: The DUT failed to calculate the product of the multiplication correctly");
            $display("for the corner case: %s x %s", case_a.name, case_b.name);
            $display("with the rounding parameter: %s", round_parameters[rounding]);
            $display("The product is:    %h with sign: %h, exponent: %h, mantissa: %h", z[rounding], z[rounding][31], z[rounding][30:23], z[rounding][22:0]);
            $display("When it should be: %h with sign: %h, exponent: %h, mantissa: %h", z_func[rounding], z_func[rounding][31], z_func[rounding][30:23], z_func[rounding][22:0]);
        end
    end
end

endmodule