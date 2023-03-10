pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


template BundlerVerifier(nInputs) {

  signal input userOps[nInputs];

  signal input enabled[nInputs];
  signal input Axs[nInputs];
  signal input Ays[nInputs];
  signal input R8x[nInputs];
  signal input R8y[nInputs];
  signal input S[nInputs];
  signal input M[nInputs];

  signal output userOpsHash;

  component signVerifiers[nInputs];
  component hash;

  for(var i=0; i < nInputs; i++) {
    signVerifiers[i] = EdDSAPoseidonVerifier();
  }

  hash = Poseidon(1);
  var dataSum = 0;
  
  for(var i=0; i < nInputs; i++) {
    dataSum += userOps[i];
    signVerifiers[i].enabled <== enabled[i];
    signVerifiers[i].Ax <== Axs[i];
    signVerifiers[i].Ay <== Ays[i];
    signVerifiers[i].R8x <== R8x[i];
    signVerifiers[i].R8y <== R8y[i];
    signVerifiers[i].S <== S[i];
    signVerifiers[i].M <== M[i];
  }

  hash.inputs[0] <== dataSum;
  userOpsHash <== hash.out;

}

component main = BundlerVerifier(128);