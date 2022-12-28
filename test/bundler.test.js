const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;
const wasm_tester = require("circom_tester").wasm;

const chai = require("chai");
const path = require("path");
const assert = chai.assert;

describe('Bundler Test', function() {
  this.timeout(1000000);
  before(async() => {
    eddsa = await buildEddsa();
    babyJub = await buildBabyjub();
    F = babyJub.F;
    circuit = await wasm_tester(path.join(__dirname, "circom", "bundler_test.circom"));
    eddsaPoseidonCircuit = await wasm_tester(path.join(__dirname, "circom", "eddsaposeidon_test.circom"));
    multiplierCircuit = await wasm_tester(path.join(__dirname, "../circom/multiplier2", "multiplier2.circom"));

  });
  it('test eddsa posidon', async () => {
    const msg = F.e(1234);

    const prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090001", "hex");

    const pubKey = eddsa.prv2pub(prvKey);

    const signature = eddsa.signPoseidon(prvKey, msg);

    assert(eddsa.verifyPoseidon(msg, signature, pubKey));

    const input = {
        enabled: 1,
        Ax: F.toObject(pubKey[0]),
        Ay: F.toObject(pubKey[1]),
        R8x: F.toObject(signature.R8[0]),
        R8y: F.toObject(signature.R8[1]),
        S: signature.S,
        M: F.toObject(msg)
    };

    // console.log(JSON.stringify(utils.stringifyBigInts(input)));

    const w = await eddsaPoseidonCircuit.calculateWitness(input, true);
    // console.log(`witness1= ${JSON.stringify(w)}`)

    await eddsaPoseidonCircuit.checkConstraints(w);
  });

  it('base test', async () => {
    const msg = F.e(1234);
    console.log(`msg ${JSON.stringify(msg)}`)

    const prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090001", "hex");
    const prvkey1 = Buffer.from("0001020304050607080900010203040506070809000102030405060708090007", "hex");

    const pubKey = eddsa.prv2pub(prvKey);
    const pubKey1 = eddsa.prv2pub(prvkey1);
    console.log(`pubKey ${pubKey}`)

    const signature = eddsa.signPoseidon(prvKey, msg);
    console.log(`signature ${JSON.stringify(signature)}`)

    assert(eddsa.verifyPoseidon(msg, signature, pubKey));
    const arrayLen = 16;
    const input = {
      enabled: new Array(arrayLen).fill(1).map((v,i) => 1),
      userOps: new Array(arrayLen).fill(1).map((v,i) => F.toObject(msg)),
      Axs: new Array(arrayLen).fill(1).map((v,i) =>F.toObject(pubKey[0])), // [F.toObject(pubKey[0]), F.toObject(pubKey[0])],
      Ays: new Array(arrayLen).fill(1).map((v,i) => F.toObject(pubKey[1])), //[F.toObject(pubKey[1]), F.toObject(pubKey[1])],
      R8x:  new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[0])),// [F.toObject(signature.R8[0]), F.toObject(signature.R8[0])],
      R8y: new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[1])), //[F.toObject(signature.R8[1]), F.toObject(signature.R8[1])],
      S: new Array(arrayLen).fill(1).map((v,i) => signature.S),//[signature.S, signature.S],
      M: new Array(arrayLen).fill(1).map((v,i) => F.toObject(msg)),//[F.toObject(msg), F.toObject(msg)],
    }
    
    const w = await circuit.calculateWitness(input,true)
    // console.log(`witness ${JSON.stringify(w)}`)
    await circuit.checkConstraints(w);

  });
})