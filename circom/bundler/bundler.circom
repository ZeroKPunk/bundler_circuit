pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


template BundlerVerifier(nInputs) {

  signal input enableds[nInputs];
  signal input Axs[nInputs];
  signal input Ays[nInputs];
  signal input R8xs[nInputs];
  signal input R8ys[nInputs];
  signal input Ss[nInputs];
  signal input Ms[nInputs];

  signal output userOpsHash;

  component signVerifiers[nInputs];
  component hash;

  hash = Poseidon(1);

  for(var i=0; i < nInputs; i++) {
    signVerifiers[i] = EdDSAPoseidonVerifier();
  }

  var dataLen = nInputs;
  var hashSum = 0;
  for(var i=0; i < nInputs; i++) {
    hashSum += Ms[i];
  }
  
  for(var i=0; i < nInputs; i++) {
    
    signVerifiers[i].enabled <== enableds[i];
    signVerifiers[i].Ax <== Axs[i];
    signVerifiers[i].Ay <== Ays[i];
    signVerifiers[i].R8x <== R8xs[i];
    signVerifiers[i].R8y <== R8ys[i];
    signVerifiers[i].S <== Ss[i];
    signVerifiers[i].M <== Ms[i];
  }
  hash.inputs[0] <== hashSum;
  userOpsHash <== hash.out;

}

component main = BundlerVerifier(128);