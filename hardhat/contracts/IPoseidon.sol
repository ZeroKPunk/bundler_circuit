// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IPoseidon4 {
  function poseidon(uint256[4] calldata ops) external pure returns (uint256);
}
