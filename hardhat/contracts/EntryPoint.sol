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

  function UserOpKeccak256(UserOperation calldata op) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(op.sender, op.callData));
  }

  function verifyUserOpHash(UserOperation[] calldata ops, uint[32] memory inputs) public returns (bool) {
    console.log("start verifyUserOpHash");
    uint opsLen = ops.length;
    uint stepLen = 4;
    for(uint i = 0;i < opsLen; i += stepLen) {
      uint256[4] memory poseidonInput ;
      for(uint j = 0; j < stepLen; j++) {
        // TODO: should encodePacked All Params!
        
        bytes32 UserOpHash = UserOpKeccak256(ops[i]);
        console.logBytes32(UserOpHash);
        poseidonInput[j] = uint(UserOpHash);

      }
      console.log("Solidity poseidonInput %s poseidonInput %s", poseidonInput[0], poseidonInput[1]);
      uint256 Poseidon4Result = IPoseidon4(_poseidonHash).poseidon(poseidonInput);
      console.log("Poseidon4Result %d inputs[i / stepLen] %d", Poseidon4Result, inputs[i / stepLen]);
      
      require(IPoseidon4(_poseidonHash).poseidon(poseidonInput) == inputs[i / stepLen]);
      
    }
    return true;
  }

  function handleOps(
      UserOperation[] calldata ops, 
      uint[2] memory a,
      uint[2][2] memory b,
      uint[2] memory c,
      uint[32] memory input
  ) public {
    console.log("Start here");

    require(bundlerZkVerifier.verifyProof(a, b, c, input), "ZKP verifiy error");
    console.log("Verify ZKP Success!");

    require(verifyUserOpHash(ops, input), "Verify UserOpHash error");

    console.log("Verify Hash And Signatrue success");
    
  }

}