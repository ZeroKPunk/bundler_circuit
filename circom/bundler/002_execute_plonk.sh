#!/bin/bash

mkdir -p tmp_plonk_zk_process
cd tmp_plonk_zk_process


compile_start=`date +%s.%N`
# Compile the circuit
circom ../bundler.circom --r1cs --wasm --sym --c

compile_end=`date +%s.%N`

compile_runtime=$( echo "$compile_end - $compile_start" | bc -l )

echo "=============compile_runtime $compile_runtime"

generatezk_start=`date +%s.%N`

# Generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions
snarkjs plonk setup bundler.r1cs ../tmp_powers_of_tao/pot19_final.ptau circuit_final.zkey

# Export the zkey
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

generatezk_end=`date +%s.%N`

generatezk_runtime=$( echo "$generatezk_end - $generatezk_start" | bc -l )

echo "=============generatezkey_runtime $generatezk_runtime"

# Copy the input file inside the sudoku_js directory
cp ../input.json bundler_js/input.json

prove_start=`date +%s.%N`
# Go inside the sudoku_js directory and generate the witness.wtns
cd bundler_js
node generate_witness.js bundler.wasm input.json witness.wtns

# Copy the witness.wtns to the outside and go there
cp witness.wtns ../witness.wtns
cd ..
# Create the Proof 
snarkjs plonk prove circuit_final.zkey witness.wtns proof.json public.json

prove_end=`date +%s.%N`

prove_runtime=$( echo "$prove_end - $prove_start" | bc -l )

echo "=============prove_end $prove_runtime"

# Verify
snarkjs plonk verify verification_key.json public.json proof.json

# Export Verify solidity
snarkjs zkey export solidityverifier circuit_final.zkey verifier.sol

# Export solidity calldata 
snarkjs zkey export soliditycalldata public.json proof.json
