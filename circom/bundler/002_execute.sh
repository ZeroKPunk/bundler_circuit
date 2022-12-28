#!/bin/bash

mkdir -p tmp_zk_process
cd tmp_zk_process

# Compile the circuit
circom ../bundler.circom --r1cs --wasm --sym --c

# Copy the input file inside the sudoku_js directory
cp ../input.json bundler_js/input.json

# Go inside the sudoku_js directory and generate the witness.wtns
cd bundler_js
node generate_witness.js bundler.wasm input.json witness.wtns

# Copy the witness.wtns to the outside and go there
cp witness.wtns ../witness.wtns
cd ..


# Generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions
snarkjs plonk setup bundler.r1cs ../tmp_powers_of_tao/pot19_final.ptau circuit_final.zkey


# Export the zkey

snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

# Create the Proof 

time snarkjs plonk prove circuit_final.zkey witness.wtns proof.json public.json