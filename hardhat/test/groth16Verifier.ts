import { expect } from "chai";
import { ethers,  BigNumber } from "ethers"
import { ethers as ethersHardhat } from "hardhat"
import * as poseidonGenContract from "./poseidon4ABI.json"
import * as poseidon1GenContract from "./poseidon1ABI.json"

import { EntryPoint__factory } from "../typechain-types"
import { UserOperationStruct } from "../typechain-types/EntryPoint"
import { json, string } from "hardhat/internal/core/params/argumentTypes";

const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;
const buildPoseidonOpt = require("circomlibjs").buildPoseidonOpt;
const fs = require('fs');

function JSONStringfiy(input:any) {
  return JSON.stringify(input, (_, v) => typeof v === 'bigint' ? v.toString() : v)
}

function writeJson(data:any, jsonFilePath:string){
  JSON.stringify(data, (_, v) => typeof v === 'bigint' ? v.toString() : v)
  fs.writeFileSync(jsonFilePath, JSON.stringify(data, null, 4), 'utf-8');
}

function convertUserOpToPoseidonInput(userOp: UserOperationStruct) {

  const abiCoder = new ethers.utils.AbiCoder
  let sumHash = BigNumber.from(0)
  // paramSender.push(userOp.sender)
  // paramCallData.push(userOp.callData)
  const keccak256Hash = ethers.utils.keccak256(abiCoder.encode(["address","uint256", "bytes"],[userOp.sender, userOp.nonce, userOp.callData]))
  // console.log(`convertUserOpToPoseidonInput-keccak256Hash ${keccak256Hash}`)
  // console.log(`convertUserOpToPoseidonInput-parseInt >> 10 ${parseInt(keccak256Hash, 16)}`)
  var d = BigNumber.from(BigInt(keccak256Hash).toString(10))
  // console.log(`BigInt(keccak256Hash).toString(10) ${BigInt(keccak256Hash).toString(10)} BigNumberToString ${d.toString()} d.shr(10) ${d.shr(10).toString()}`)
  sumHash = sumHash.add(d.shr(10))

  console.log(`PoseidonCircuitInput= ${(sumHash.toString())}`)
  return sumHash.toString()
}

async function main() {

  const account0 = (await ethersHardhat.getSigners())[0]
  const provider = ethersHardhat.provider

  const abi = poseidon1GenContract.abi
  const bytecode = poseidon1GenContract.bytecode

  const factory = new ethers.ContractFactory(abi, bytecode, account0)
  const PoseidonContract1 = await factory.deploy()
  // console.log(`Interface ${JSON.stringify(PoseidonContract4.interface)}`)

  const PoseidonContract1Address = PoseidonContract1.address
  await PoseidonContract1.deployTransaction.wait()
  console.log(`PoseidonContract1Address ${PoseidonContract1Address}`)

  const entryPoint = await new EntryPoint__factory(account0).deploy(PoseidonContract1Address)

  console.log(`entryPoint Address ${entryPoint.address}`)
  

  const eddsa = await buildEddsa();
  const babyJub = await buildBabyjub();
  const poseidonOpt = await buildPoseidonOpt();
  const F = babyJub.F;
  const userOp: UserOperationStruct = {
    sender: "0x9DE629d280bd0662D21a925cb71372fDE78c7ed4",
    nonce: BigNumber.from(1),
    initCode: "0x736466736466",
    callData: "0x736466736466",
    callGasLimit:  BigNumber.from(1),// PromiseOrValue<BigNumberish>;
    verificationGasLimit: BigNumber.from(1), //PromiseOrValue<BigNumberish>;
    preVerificationGas: BigNumber.from(1), //PromiseOrValue<BigNumberish>;
    maxFeePerGas: BigNumber.from(1), //PromiseOrValue<BigNumberish>;
    maxPriorityFeePerGas: BigNumber.from(1), //PromiseOrValue<BigNumberish>;
    paymasterAndData: "0x736466736466",//PromiseOrValue<BytesLike>;
    signature: "0x736466736466"//PromiseOrValue<BytesLike>;
  }

  const arrayLen = 128;

  const userOps: UserOperationStruct[] = new Array(arrayLen).fill(1).map((v,i) => userOp)

  

  const hashBigInt = convertUserOpToPoseidonInput(userOp)

  const poseidon1Result = await PoseidonContract1['poseidon(uint256[1])']([hashBigInt]);
  console.log(`poseidon1SolidityResult ${JSON.stringify(poseidon1Result)}`)

  const poseidon1OfflineResult = poseidonOpt([hashBigInt])
  console.log(`poseidon1OfflineResult ${JSONStringfiy(F.toObject(poseidon1OfflineResult))}`)

  // await entryPoint.UserOpKeccak256()

  
  const msg = F.e(hashBigInt);
  console.log(`F.toObject(msg) ${F.toObject(msg)}`)

  const prvKey = Buffer.from("000102030405060708090001020304050607080900010203040506070809", "hex");

  const pubKey = eddsa.prv2pub(prvKey);

  const signature = eddsa.signPoseidon(prvKey, msg);
  
  const input = {
    enableds: new Array(arrayLen).fill(1).map((v,i) => 1),
    Axs: new Array(arrayLen).fill(1).map((v,i) => F.toObject(pubKey[0])), // [F.toObject(pubKey[0]), F.toObject(pubKey[0])],
    Ays: new Array(arrayLen).fill(1).map((v,i) => F.toObject(pubKey[1])), //[F.toObject(pubKey[1]), F.toObject(pubKey[1])],
    R8xs:  new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[0])),// [F.toObject(signature.R8[0]), F.toObject(signature.R8[0])],
    R8ys: new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[1])), //[F.toObject(signature.R8[1]), F.toObject(signature.R8[1])],
    Ss: new Array(arrayLen).fill(1).map((v,i) => signature.S),//[signature.S, signature.S],
    Ms: new Array(arrayLen).fill(1).map((v,i) => F.toObject(msg)),//[F.toObject(msg), F.toObject(msg)],
  }
  // console.log(`input ${JSON.stringify(input, (_, v) => typeof v === 'bigint' ? v.toString() : v)}`)
  // writeJson(input, 'test.json')
  const a:[string,string] = ["0x061212f4f2a2a50b363cba0491e0babb961204bd06010516072770ea9e7be541", "0x10ff7adc4d7582f06a54431d6c461baec1edcf9bcd49147c8eb366ebc340dfe7"]
  const b:[[string,string],[string,string]] = [["0x2d38fc46953321c26dc33bec7a3e0521f624a4a70d0de67aa02e73bfef257ac0", "0x262ffe29a3893332acb2c391a8b757cc8fbd07b45ada168f0b60dbf64910d80c"],["0x1c9ea55ed0fcb1fcf3bbb7b526c55d2e9056355800ff6ea797250c368b90e963", "0x1326f03417336090c0f3779246c3596f68af1951af7686415a6afd13f2dd0902"]]
  const c:[string, string] = ["0x2f314b48061732a6eac6c9b2e080823be38701aff4573ee133229f01b285e454", "0x16444a126b299a958752cf6e7128c84db93aa4ed6b6a23614cb8a830eac4a57e"]
  const pInput:[string] = ["0x18c39ce41f8d249563cbf8318c50c2d50eb277ad4df4c01c37131d501672ca3c"]
  const tx = await entryPoint.handleOps(userOps, a, b, c, pInput)

  await tx.wait()
  const txResult = await provider.getTransactionReceipt(tx.hash)
  console.log(`VerifyProof txHash ${tx.hash} gasUsed ${txResult.gasUsed}`)

  // console.log(`eddsaPoseidon input ${(input)}`)

  eddsa.verifyPoseidon(msg, signature, pubKey);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});