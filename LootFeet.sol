// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootFeet is LootItem {
	constructor() LootItem("Programmable Loot [Feet]", "pLOOT/FEET") {
		items = [
			"Abarka",
			"Anklets",
			"Areni-1 shoes",
			"Ballet flats",
			"Ballet shoes",
			"Bast shoes",
			"Bearpaws",
			"Boat shoes",
			"Boots",
			"Chopines",
			"Chukka boots",
			"Climbing shoes",
			"Clogs",
			"Combat boots",
			"Court shoes",
			"Cowboy boots",
			"Crakow",
			"Creepers",
			"Espadrilles",
			"Flip-flops",
			"Footwraps",
			"Galesh",
			"Galoshes",
			"Getas",
			"High-heeled footwear",
			"High-tops",
			"Hiking boots",
			"Ice skates",
			"Jika-tabi",
			"Kitten heels",
			"Klompen",
			"Kolhapuri chappals",
			"Loafers",
			"Moccasins",
			"Mukluk",
			"Opanci",
			"Paduka",
			"Pampooties",
			"Pattens",
			"Peshawari chappals",
			"Platform shoes",
			"Pointe shoes",
			"Poulaine",
			"Riding boots",
			"Sabaton",
			"Sabot",
			"Sailing boots",
			"Sandals",
			"Sea-boots",
			"Shoes",
			"Skate shoes",
			"Ski boots",
			"Slides",
			"Slippers",
			"Sneakers",
			"Snowshoes",
			"Socks",
			"Soles",
			"Swimfins",
			"Tabi",
			"Toe socks",
			"Valenki",
			"Veldskoen",
			"Waders",
			"Wellington boots",
			"Winklepickers"
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
		mintItem(to, container, Items.FEET, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.FEET);
	}
}
