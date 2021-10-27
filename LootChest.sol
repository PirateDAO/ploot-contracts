// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootChest is LootItem {
	constructor() LootItem("Programmable Loot [Chest]", "pLOOT/CHEST") {
		items = [
			"Aketon",
			"Apron",
			"Armour",
			"Bikini",
			"Boiled leather",
			"Bra",
			"Breastplate",
			"Brigandine",
			"Caftan",
			"Chainmail",
			"Chemise",
			"Chestplate",
			"Chiton",
			"Cotehardie",
			"Cuirass",
			"Culet",
			"Dendra panoply",
			"Doublet",
			"Draped toga",
			"Dyed jacket",
			"Ezor",
			"Faulds",
			"Gambeson",
			"Garment",
			"Hakama",
			"Hanfu",
			"Hauberk",
			"Hide",
			"Himation",
			"Jacket",
			"Jerkin",
			"Karuta",
			"Kimono",
			"Kirtle",
			"Kolpos",
			"Kuttoneth",
			"Lamellar armour",
			"Laminar armour",
			"Linen shirt",
			"Loincloth",
			"Mail armour",
			"Mantle",
			"Maximilian armour",
			"Muscle cuirass",
			"Palla",
			"Peplos",
			"Plackart",
			"Plate armour",
			"Poet shirt",
			"Pourpoint",
			"Quilted vest",
			"Robe",
			"Sari",
			"Scale armour",
			"Shell armour",
			"Shirt",
			"Simla",
			"Stola",
			"Tarkhan",
			"Toga",
			"Tunic",
			"Vest",
			"Work shirt"
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
		mintItem(to, container, Items.CHEST, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.CHEST);
	}
}
