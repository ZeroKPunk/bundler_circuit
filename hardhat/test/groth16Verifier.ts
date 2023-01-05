import { expect } from "chai";
import { ethers,  BigNumber } from "ethers"
import { ethers as ethersHardhat } from "hardhat"
import * as poseidonGenContract from "./poseidon4ABI.json"

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
  const string1 = ethers.utils.solidityPack(["address", "bytes"],[userOp.sender, userOp.callData])
  console.log(`string1 ${JSON.stringify(string1)}`)
  const hash1 = ethers.utils.keccak256(string1)
  console.log(`solidityKeccak256 hash1 ${JSON.stringify(hash1)}`)
  // const hashBigInt = BigNumber.from(string1).toString()
  // const hashBigInt = parseInt(hash1,16)
  var bn = BigInt(hash1)
  var hashBigInt = bn.toString(10)
  console.log(`PoseidonCircuitInput= ${(hashBigInt.toString())}`)
  return hashBigInt.toString()
}

// const poseidonGenContract = require('circomlibjs/src/poseidon_gencontract.js')

// poseidonGenContract.generateABI(5)
// poseidonGenContract.createCode(5)


async function main() {

  const account0 = (await ethersHardhat.getSigners())[0]
  const provider = ethersHardhat.provider

  const abi = poseidonGenContract.abi
  const bytecode = poseidonGenContract.bytecode

  const factory = new ethers.ContractFactory(abi, bytecode, account0)
  const PoseidonContract4 = await factory.deploy()
  // console.log(`Interface ${JSON.stringify(PoseidonContract4.interface)}`)

  const PoseidonContract4Address = PoseidonContract4.address
  await PoseidonContract4.deployTransaction.wait()
  console.log(`PoseidonContract1Address ${PoseidonContract4Address}`)

  const entryPoint = await new EntryPoint__factory(account0).deploy(PoseidonContract4Address)

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

  const poseidon4Result = await PoseidonContract4['poseidon(uint256[4])']([hashBigInt,hashBigInt, hashBigInt, hashBigInt]);
  console.log(`poseidon4SolidityResult ${JSON.stringify(poseidon4Result)}`)

  const poseidon4OfflineResult = poseidonOpt([hashBigInt,hashBigInt,hashBigInt,hashBigInt])
  console.log(`poseidon4OfflineResult ${JSONStringfiy(F.toObject(poseidon4OfflineResult))}`)

  // await entryPoint.UserOpKeccak256()

  
  const msg = F.e(hashBigInt);
  console.log(`F.toObject(msg) ${F.toObject(msg)}`)

  const prvKey = Buffer.from("000102030405060708090001020304050607080900010203040506070809", "hex");

  const pubKey = eddsa.prv2pub(prvKey);

  const signature = eddsa.signPoseidon(prvKey, msg);
  
  const input = {
    enabled: new Array(arrayLen).fill(1).map((v,i) => 1),
    userOps: new Array(arrayLen).fill(1).map((v,i) => F.toObject(msg)),
    Axs: new Array(arrayLen).fill(1).map((v,i) => F.toObject(pubKey[0])), // [F.toObject(pubKey[0]), F.toObject(pubKey[0])],
    Ays: new Array(arrayLen).fill(1).map((v,i) => F.toObject(pubKey[1])), //[F.toObject(pubKey[1]), F.toObject(pubKey[1])],
    R8x:  new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[0])),// [F.toObject(signature.R8[0]), F.toObject(signature.R8[0])],
    R8y: new Array(arrayLen).fill(1).map((v,i) => F.toObject(signature.R8[1])), //[F.toObject(signature.R8[1]), F.toObject(signature.R8[1])],
    S: new Array(arrayLen).fill(1).map((v,i) => signature.S),//[signature.S, signature.S],
    M: new Array(arrayLen).fill(1).map((v,i) => F.toObject(msg)),//[F.toObject(msg), F.toObject(msg)],
  }
  // console.log(`input ${JSON.stringify(input, (_, v) => typeof v === 'bigint' ? v.toString() : v)}`)
  // writeJson(input, 'test.json')
  const a:[string,string] = ["0x0b9b7c277bd2194f7457258f304f1a32f53e3717d66cb6ba40e7b86183f6e28d", "0x0f70323e63be5c953e8774ade6be03ffdc2fc8ba794cdfeb6467b29d92da1beb"]
  const b:[[string,string],[string,string]] = [["0x10b3fd2bc0f8c21bb4b2f27cd163fc8455317a542431694636abacccf1e647de", "0x05af54597ec18394c40c12a9ca2d4b9decc0fb1656f4ac2217dac474fa629808"],["0x289a887b68f1f26371b9e8b529c5c74258a9f4aebb5928125a3910d817277dad", "0x10dffdad17cf4b953b21d58ddcc766eca1401c9b14435893de9b8bc0a2a6363e"]]
  const c:[string, string] = ["0x1e405668e1d08b351825ed4a33d1903ccb5943fdb30beaa5bbb72543f5df869e", "0x21fc18f9de91461b637a81ac3a4dc9cf6e944d2c859d2eabe1743d1553f7c8c4"]
  const pInput = ["0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd","0x0b27001291cc519156df153ac419d89f8c0798f7454568915460758aba85b1fd"]
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