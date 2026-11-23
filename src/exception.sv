module exception_mult (
    input string round,
    input logic [31:0] a, b, z_calc,
    input logic overflow, underflow, inexact,
    output logic [31:0] z,
    output logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f
);

logic sign;

typedef enum { ZERO, INF, NORM, MIN_NORM, MAX_NORM } interp_t;
interp_t A, B;
function interp_t num_interp (logic [31:0] signal);
    interp_t interp;
    if (signal[30:23] == '0) interp = ZERO; // Denormals are considered zeros
    else if (signal[30:23] == '1) interp = INF; // NaNs are considered infinites
    else if (signal[30:23] == 1'b1 && signal[22:0] == '0) interp = MIN_NORM;
    else if (signal[30:23] == {{7{1'b1}}, 1'b0} && signal[22:0] == '1) interp = MAX_NORM;
    else interp = NORM;
    return interp;
endfunction

function [30:0] z_num (interp_t interp);
    logic [30:0] num;
    case(interp)
        ZERO: num = '0;
        INF: num = {{8{1'b1}}, {23{1'b0}}};
        MIN_NORM: num = {{7{1'b0}}, 1'b1, {23{1'b0}}};
        MAX_NORM: num = {{7{1'b1}}, 1'b0, {23{1'b1}}};
        default: num = {31{1'bX}};
    endcase
    return num;
endfunction

always_comb begin
    sign = z_calc[31];
    {zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f} = '0;
    A = num_interp(a);
    B = num_interp(b);
    unique case({num_interp(a), num_interp(b)}) inside
        {NORM, NORM}: begin
            if (overflow) begin
                // based on the 'round' parameter and the sign of the 'z_calc' signal, 
                // round the output either to maxNormal number or to infinity
                unique if (round == "IEEE_pinf") begin
                    if (sign) huge_f = 1; else inf_f = 1;
                end
                else if (round == "IEEE_ninf") begin
                    if (sign) inf_f = 1; else huge_f = 1;
                end
                else if (round == "IEEE_zero") huge_f = 1;
                else inf_f = 1;
            end
            else if (underflow) begin
                // based on the same criteria, round the output either to minNormal or to zero
                unique if (round inside {"IEEE_near", "IEEE_zero", "near_up"}) zero_f = 1;
                else if (round == "IEEE_pinf") begin
                    if (sign) zero_f = 1; else tiny_f = 1;
                end
                else if (round == "IEEE_ninf") begin
                    if (sign) tiny_f = 1; else zero_f = 1;
                end
                else tiny_f = 1;
            end
            else begin
                if (z_calc[30:23] == '1) begin
                    unique if (round == "IEEE_pinf") begin
                        if (sign) huge_f = 1; else inf_f = 1;
                    end
                    else if (round == "IEEE_ninf") begin
                        if (sign) inf_f = 1; else huge_f = 1;
                    end
                    else if (round == "IEEE_zero") huge_f = 1;
                    else inf_f = 1;
                end 
                else if (z_calc[30:23] == '0) begin
                    unique if (round inside {"IEEE_near", "IEEE_zero", "near_up"}) zero_f = 1;
                    else if (round == "IEEE_pinf") begin
                        if (sign) zero_f = 1; else tiny_f = 1;
                    end
                    else if (round == "IEEE_ninf") begin
                        if (sign) tiny_f = 1; else zero_f = 1;
                    end
                    else tiny_f = 1;
                end 
                else inexact_f = inexact;
            end
        end
        {ZERO, ZERO}, {ZERO, NORM}, {NORM, ZERO}: zero_f = 1;
        {INF, INF}, {INF, NORM}, {NORM, INF}: inf_f = 1;
        {ZERO, INF}, {INF, ZERO}: nan_f = 1;
    endcase
    unique if (inf_f) begin z = {sign, z_num(INF)}; if(overflow && A == NORM && B == NORM) huge_f = 1; end
    else if (zero_f) begin z = {sign, z_num(ZERO)}; if(underflow && A == NORM && B == NORM) tiny_f = 1; end
    else if (huge_f) z = {sign, z_num(MAX_NORM)};
    else if (tiny_f) z = {sign, z_num(MIN_NORM)};
    else if (nan_f) begin z = {1'b0, z_num(INF)}; inf_f = 1; end 
    else z = z_calc;
end

endmodule