pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


template BundlerVerifier(nInputs) {

  var stepLength = 4;
  assert(nInputs % stepLength == 0);

  signal input userOps[nInputs];

  signal input enabled[nInputs];
  signal input Axs[nInputs];
  signal input Ays[nInputs];
  signal input R8x[nInputs];
  signal input R8y[nInputs];
  signal input S[nInputs];
  signal input M[nInputs];

  signal output userOpsHash[nInputs / stepLength];

  component signVerifiers[nInputs];
  component hashes[nInputs / stepLength];

  for(var i=0; i < nInputs; i++) {
    signVerifiers[i] = EdDSAPoseidonVerifier();
  }

  var dataLen = nInputs;
  for(var i=0; i < nInputs; i += stepLength) {
    hashes[i / stepLength] = Poseidon(stepLength);
    for(var j=0; j < stepLength; j++) {
      hashes[i / stepLength].inputs[j] <== userOps[i+j];
    }
  }

  
  for(var i=0; i < nInputs; i++) {
    
    signVerifiers[i].enabled <== enabled[i];
    signVerifiers[i].Ax <== Axs[i];
    signVerifiers[i].Ay <== Ays[i];
    signVerifiers[i].R8x <== R8x[i];
    signVerifiers[i].R8y <== R8y[i];
    signVerifiers[i].S <== S[i];
    signVerifiers[i].M <== M[i];
  }

  for(var i=0;i < nInputs / stepLength; i++) {
    // log(hashes[i].out);
    userOpsHash[i] <== hashes[i].out;

  }

}

component main = BundlerVerifier(128);