mkdir -p tmp_powers_of_tao

cd tmp_powers_of_tao

snarkjs powersoftau new bn128 19 pot19_0000.ptau -v

snarkjs powersoftau contribute pot19_0000.ptau pot19_0001.ptau --name="First contribution" -v

snarkjs powersoftau contribute pot19_0000.ptau pot19_0002.ptau --name="Second contribution" -v -e="some random text"

# take a long time ...
snarkjs powersoftau beacon pot19_0002.ptau pot19_beacon.ptau 0101930405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"

snarkjs powersoftau prepare phase2 pot19_beacon.ptau pot19_final.ptau -v

snarkjs powersoftau verify pot19_final.ptau
