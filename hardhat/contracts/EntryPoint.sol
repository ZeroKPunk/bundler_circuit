/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./Verifier.sol";
import "./ConvertStuff.sol";
import "./IPoseidon.sol";

import "hardhat/console.sol";

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

contract EntryPoint {

  // using Verifier for Pairing;

  struct Proof {
    Pairing.G1Point A;
    Pairing.G2Point B;
    Pairing.G1Point C;
  }

  Verifier private immutable bundlerZkVerifier = new Verifier();
  ConvertStuff private immutable converter = new ConvertStuff();
  address private _poseidonHash;

  constructor(address poseidonHash) {
    _poseidonHash = poseidonHash;
  }

  function keccak256UserOpsSum(UserOperation[] calldata ops) public pure returns (uint256) {
    uint opsLen = ops.length;
    uint hashSum = 0;
    address[] memory senders;
    bytes[] memory callDatas;
    for(uint i = 0; i < opsLen; i++){
      hashSum += uint(keccak256(abi.encode(ops[i].sender, ops[i].nonce, ops[i].callData))) >> 10 ;
    }
    return hashSum;
  }

  function verifyUserOpHash(UserOperation[] calldata ops, uint[1] memory inputs) public returns (bool) {
    console.log("start verifyUserOpHash");
    uint opsLen = ops.length;
    uint256 poseidonInput = keccak256UserOpsSum(ops);
    require(IPoseidon1(_poseidonHash).poseidon([poseidonInput]) == inputs[0]);
    return true;
  }

  function handleOps(
      UserOperation[] calldata ops, 
      uint[2] memory a,
      uint[2][2] memory b,
      uint[2] memory c,
      uint[1] memory input
  ) public {
    console.log("Start here");

    require(bundlerZkVerifier.verifyProof(a, b, c, input), "ZKP verifiy error");
    console.log("Verify ZKP Success!");

    require(verifyUserOpHash(ops, input), "Verify UserOpHash error");

    console.log("Verify Hash And Signatrue success");
    
  }

}