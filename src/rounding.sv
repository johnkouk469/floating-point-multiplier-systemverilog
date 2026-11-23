module round_mult (
    input string round,
    input logic [23:0] mantissa, 
    input logic guard_bit, sticky_bit, sign,
    output logic [24:0] result, 
    output logic inexact
);

always_comb begin
    if (guard_bit == 0 && sticky_bit == 0) inexact = 0; else inexact = 1;
    if(!inexact)
        result = mantissa;
    else begin
        case(round)
            "IEEE_near": begin
                if (guard_bit) begin
                    if (sticky_bit)
                        result = mantissa + 1;
                    else begin
                        if (mantissa[0]) result = mantissa + 1;
                        else result = mantissa;
                    end
                end
                else result = mantissa;
            end
            "IEEE_zero": result = mantissa;
            "IEEE_pinf": if (sign) result = mantissa; else result = mantissa + 1;
            "IEEE_ninf": if (sign) result = mantissa + 1; else result = mantissa;
            "near_up": begin
                if (guard_bit) begin
                    if (sticky_bit)
                        result = mantissa + 1;
                    else begin
                        if (sign) result = mantissa;
                        else 
                        result = mantissa + 1;
                    end
                end
                else result = mantissa;
            end
            "away_zero": result = mantissa + 1;
            default: result = {25{1'bX}};
        endcase
    end    
end

endmodule