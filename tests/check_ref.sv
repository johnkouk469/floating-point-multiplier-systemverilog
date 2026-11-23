// Reads a dump file (+file=<name>) written by random_tb.sv or directed_tb.sv and compares
// the product z of every line with the reference function multiplication() from
// src/multiplication.sv. Prints one summary line per rounding mode and exits with $fatal
// if there is any mismatch.
`include "multiplication.sv"

module check_ref;
    function string rname(integer i);
        case (i)
            0: rname = "IEEE_near"; 1: rname = "IEEE_zero"; 2: rname = "IEEE_pinf";
            3: rname = "IEEE_ninf"; 4: rname = "near_up"; default: rname = "away_zero";
        endcase
    endfunction

    string file;
    integer fd, rc, r, total, fails;
    integer per_total [0:5];
    integer per_fail [0:5];
    reg [31:0] a, b, z, exp_z;
    reg [7:0] st;

    initial begin
        if (!$value$plusargs("file=%s", file)) $fatal(1, "usage: vvp check_ref.vvp +file=<dump file>");
        fd = $fopen(file, "r");
        total = 0; fails = 0;
        for (r = 0; r < 6; r++) begin per_total[r] = 0; per_fail[r] = 0; end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%d %h %h %h %h\n", r, a, b, z, st);
            if (rc == 5) begin
                exp_z = multiplication(rname(r), a, b);
                total++; per_total[r]++;
                if (exp_z !== z) begin
                    fails++; per_fail[r]++;
                    if (fails <= 10) $display("MISMATCH round=%s a=%h b=%h dut=%h ref=%h", rname(r), a, b, z, exp_z);
                end
            end
        end
        for (r = 0; r < 6; r++) $display("%s: %0d compared, %0d mismatches", rname(r), per_total[r], per_fail[r]);
        $display("%s TOTAL: %0d compared, %0d mismatches", file, total, fails);
        if (total == 0 || fails != 0) $fatal(1, "FAIL");
        $finish;
    end
endmodule
