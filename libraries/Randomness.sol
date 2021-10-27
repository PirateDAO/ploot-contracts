// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

/// @dev Abstract class to provide for complementary "randomness"
abstract contract Randomness {
	/// @dev even weaker in rollups
	function weakSeed(uint256 nonce) internal view returns (uint256 seed) {
		seed = uint256(
			keccak256(
				abi.encodePacked(
					keccak256(abi.encodePacked(nonce)),
					keccak256(abi.encodePacked(block.timestamp)), // solhint-disable-line not-rely-on-time
					keccak256(abi.encodePacked(block.difficulty)),
					//keccak256(abi.encodePacked(block.basefee)),
					keccak256(abi.encodePacked(block.number)),
					keccak256(abi.encodePacked(block.gaslimit)),
					keccak256(abi.encodePacked(block.coinbase)),
					keccak256(abi.encodePacked(block.chainid)),
					keccak256(abi.encodePacked(msg.sender)),
					keccak256(abi.encodePacked(gasleft()))
				)
			)
		);
	}
}
