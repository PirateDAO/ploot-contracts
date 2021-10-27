// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

interface IBlackbeard {
	function sew(address dst, uint256 amount) external;

	function hasRole(bytes32 role, address account) external view returns (bool);
}
