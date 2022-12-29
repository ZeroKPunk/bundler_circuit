# bundler_circuit_snarkjs

# Configure Powers of Tau

download here : https://github.com/iden3/snarkjs

# multiplier2

## Compile the Circuit
```
circom multiplier2.circom --r1cs --wasm --sym
```

## View Information About the Circuit
```
snarkjs info -r multiplier2.r1cs
```

## To see the constraints of the circuit, execute this command
```
snarkjs r1cs print -r multiplier2.r1cs -s multiplier2.sym
```

## Calculating a Witness

```
snarkjs r1cs export json multiplier2.r1cs multiplier2.r1cs.json
head multiplier2.r1cs.json
```
## Edit input

```
vim input.json
```


## To create the witness, execute these commands:

```
cd multiplier2_js
node generate_witness.js multiplier2.wasm ../input.json ../witness.wtns
ls
ls ..
```

## Setting Up a PLONK Proving System

```
snarkjs plonk setup multiplier2.r1cs ../../snark/pot12_final.ptau multiplier2_final.zkey
```

## Export the zkey

```
snarkjs zkey export verificationkey multiplier2_final.zkey verification_key.json
```

## Create the Proof

```
snarkjs plonk prove multiplier2_final.zkey witness.wtns proof.json public.json
head proof.json
head public.json
```

## Verify the Proof
```
snarkjs plonk verify verification_key.json public.json proof.json
```