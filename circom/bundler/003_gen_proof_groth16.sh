#!/bin/bash

input_json="input128.json"

cd tmp_groth16_zk_process

prove_start=`date +%s.%N`
# Go inside the sudoku_js directory and generate the witness.wtns
cd bundler_js
node generate_witness.js bundler.wasm ../../"${input_json}" witness.wtns

# Copy the witness.wtns to the outside and go there
cp witness.wtns ../witness.wtns
cd ..
# Create the Proof 
snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json

prove_end=`date +%s.%N`
prove_runtime=$( echo "$prove_end - $prove_start" | bc -l )
echo "=============prove_runtime $prove_runtime"

snarkjs zkey export soliditycalldata public.json proof.json