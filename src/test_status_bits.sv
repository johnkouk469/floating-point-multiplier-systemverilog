module test_status_bits (input logic [7:0] status);

always_comb begin

    zero_and_infinity: assert (!(status[0] == 1'b1 && status[1] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    zero_and_invalid: assert (!(status[0] == 1'b1 && status[2] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    zero_and_huge: assert (!(status[0] == 1'b1 && status[4] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    zero_and_inexact: assert (!(status[0] == 1'b1 && status[5] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    // zero_and_unused: assert (!(status[0] == 1'b1 && status[6] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    // else $display($stime,,,"\t\t %m FAIL");

    // zero_and_div_by_zero: assert (!(status[0] == 1'b1 && status[7] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    // else $display($stime,,,"\t\t %m FAIL");

    infinity_and_tiny: assert (!(status[1] == 1'b1 && status[3] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    infinity_and_inexact: assert (!(status[1] == 1'b1 && status[5] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    // infinity_and_unused: assert (!(status[1] == 1'b1 && status[6] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    // else $display($stime,,,"\t\t %m FAIL");

    invalid_and_tiny: assert (!(status[2] == 1'b1 && status[3] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    invalid_and_huge: assert (!(status[2] == 1'b1 && status[4] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    invalid_and_inexact: assert (!(status[2] == 1'b1 && status[5] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    // invalid_and_unused: assert (!(status[2] == 1'b1 && status[6] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    // else $display($stime,,,"\t\t %m FAIL");

    tiny_and_huge: assert (!(status[3] == 1'b1 && status[4] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    tiny_and_inexact: assert (!(status[3] == 1'b1 && status[5] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    huge_and_inexact: assert (!(status[4] == 1'b1 && status[5] == 1'b1)) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    unused: assert (status[6] == 1'b0) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

    div_by_zero: assert (status[7] == 1'b0) $display($stime,,,"\t\t %m PASS");
    else $display($stime,,,"\t\t %m FAIL");

end

endmodule