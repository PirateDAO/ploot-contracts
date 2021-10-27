// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootItem } from "./ILootItem.sol";

interface ILootContainer is IERC721Enumerable, IERC721Permit {
	enum Containers {
		SACK,
		BARREL,
		CRATE,
		URN,
		COFFER,
		CHEST,
		TROVE,
		RELIQUARY
	}

	struct Container {
		Containers class;
		uint256 seed;
		uint80 timestamp;
	}

	event LootContainerMinted(
		uint256 indexed id,
		ILootContainer.Containers container,
		uint256 randomness,
		address indexed to
	);

	event LootWithdrawn(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);
	event LootDeposited(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);

	function mint(
		address to,
		Containers container,
		uint256 seed
	) external returns (uint256);

	function withdraw(
		uint256 containerId,
		ILootItem.Items item,
		address to
	) external;

	function withdrawAll(uint256 containerId, address to) external;

	function deposit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId
	) external;

	function depositWithPermit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}
