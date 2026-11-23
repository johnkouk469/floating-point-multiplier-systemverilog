#!/bin/sh
# Runs the design in Verilator and checks every product against the course's reference
# function in Icarus Verilog. Needs Verilator 5 (with --timing) and Icarus Verilog 14 on
# the PATH. Usage, from the repository root:  sh tests/run_tests.sh
# Why two simulators: Verilator builds the design but evaluates the shortreal reference
# function wrongly; Icarus evaluates the reference correctly but cannot build the design.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$root/build"
cd "$root/build"

for tb in random_tb directed_tb; do
    verilator --binary --timing -Wno-fatal -Wno-lint -Wno-SHORTREAL \
        -I../src --top-module "$tb" -Mdir "obj_$tb" "../tests/$tb.sv" > "verilator_$tb.log" 2>&1
    "./obj_$tb/V$tb" > "run_$tb.log" 2>&1
done

if grep -q "STATUS FAIL" run_directed_tb.log; then
    grep "STATUS FAIL" run_directed_tb.log
    echo "status flag check failed"
    exit 1
fi

iverilog -g2012 -I ../src -o check_ref.vvp ../tests/check_ref.sv
vvp check_ref.vvp +file=random.txt
vvp check_ref.vvp +file=directed.txt
echo "all checks passed"
