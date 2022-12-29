mkdir -p tmp_powers_of_tao

cd tmp_powers_of_tao25

snarkjs powersoftau new bn128 25 pot25_0000.ptau -v

snarkjs powersoftau contribute pot25_0000.ptau pot25_0001.ptau --name="First contribution" -v

snarkjs powersoftau contribute pot25_0000.ptau pot25_0002.ptau --name="Second contribution" -v -e="some random text"

# take a long time ...
snarkjs powersoftau beacon pot25_0002.ptau pot25_beacon.ptau 0102530405060708090a0b0c0d0e0f101112131415161718251a1b1c1d1e1f 10 -n="Final Beacon"

snarkjs powersoftau prepare phase2 pot25_beacon.ptau pot25_final.ptau -v

snarkjs powersoftau verify pot25_final.ptau
