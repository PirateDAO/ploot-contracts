// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootLegs is LootItem {
	constructor() LootItem("Programmable Loot [Legs]", "pLOOT/LEGS") {
		items = [
			"Bath towel",
			"Braies",
			"Breeches",
			"Chausses",
			"Garters",
			"Greaves",
			"Hold-ups",
			"Hose",
			"Jeans",
			"Knee highs",
			"Leggings",
			"Legwarmers",
			"Miniskirt",
			"Pants",
			"Pantyhose",
			"Shendyt",
			"Skirt",
			"Stockings",
			"Trousers",
			"Trunks",
			"Yoga pants"
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
		mintItem(to, container, Items.LEGS, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.LEGS);
	}
}
