// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootHands is LootItem {
	constructor() LootItem("Programmable Loot [Hands]", "pLOOT/HANDS") {
		items = [
			"Bands",
			"Bracers",
			"Couters",
			"Gauntlets",
			"Gloves",
			"Manacles",
			"Pauldrons",
			"Ring",
			"Vambraces",
			"Wrist irons"
		];
	}

	/**
	 * @dev See {LootContainer-mintItem}.
	 */
	function mint(
		address to,
		ILootContainer.Containers container,
		uint256 seed
	) external override onlyOwner {
		mintItem(to, container, Items.HANDS, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.HANDS);
	}
}
