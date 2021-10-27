// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootNeck is LootItem {
	constructor() LootItem("Programmable Loot [Neck]", "pLOOT/NECK") {
		items = [
			"Amulet",
			"Band",
			"Bevor",
			"Camail",
			"Cloak",
			"Cravat",
			"Elizabethan collar",
			"Falling buffe",
			"Gorget",
			"Jabot",
			"Locket",
			"Medallion",
			"Necklace",
			"Pendant",
			"Pixane",
			"Ruff",
			"Scarf",
			"Talisman",
			"Token"
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
		mintItem(to, container, Items.NECK, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.NECK);
	}
}
