// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IJollyRoger is IERC20, IERC20Metadata {
	function maximumSupply() external view returns (uint256);

	function mintable() external view returns (uint256);

	function mint(address dst, uint256 amount) external returns (bool);

	function burn(address src, uint256 amount) external returns (bool);

	function increaseAllowance(address spender, uint256 amount) external returns (bool);

	function decreaseAllowance(address spender, uint256 amount) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function metadataManager() external view returns (address);

	function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);

	function supplyManager() external view returns (address);

	function supplyFreezeEnds() external view returns (uint256);

	function supplyFreeze() external view returns (uint32);

	function supplyFreezeMinimum() external view returns (uint32);

	function supplyGrowthMaximum() external view returns (uint256);

	function setSupplyManager(address newSupplyManager) external returns (bool);

	function setMetadataManager(address newMetadataManager) external returns (bool);

	function setSupplyFreeze(uint32 period) external returns (bool);

	function setMaximumSupply(uint256 newMaxSupply) external returns (bool);
}
