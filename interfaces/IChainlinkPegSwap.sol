// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IChainlinkPegSwap {
	function swap(
		uint256 amount,
		address source,
		address target
	) external;
}
