// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootHead is LootItem {
	constructor() LootItem("Programmable Loot [Head]", "pLOOT/HEAD") {
		items = [
			"Alicorn",
			"Antlers",
			"Armet",
			"Ass-ears",
			"Balaclava",
			"Bandanna",
			"Barbute",
			"Bascinet",
			"Bashlyk",
			"Beak Hat",
			"Beak Mask",
			"Beret",
			"Bonnet",
			"Burgonet",
			"Cap",
			"Cap and bells",
			"Capirote",
			"Cervelliere",
			"Chaperon",
			"Circlet",
			"Coif",
			"Comb",
			"Coronet",
			"Cowl",
			"Crown",
			"Diadem",
			"Escoffion",
			"Eyepatch",
			"Feathers",
			"Fengguan",
			"Fujin",
			"Hairpin",
			"Hat",
			"Headband",
			"Headscarf",
			"Helm",
			"Helmet",
			"Hennin",
			"Hood",
			"Horns",
			"Kabuto",
			"Kasa",
			"Kausia",
			"Keffiyeh",
			"Khat",
			"Konos",
			"Kufi",
			"Laurels",
			"Liripipe",
			"Litham",
			"Mail coif",
			"Mask",
			"Mitre",
			"Monocle",
			"Nemes",
			"Petasos",
			"Pileus",
			"Rice Hat",
			"Sallet",
			"Snood",
			"Spangenhelm",
			"Spectacles",
			"Tiara",
			"Tricorne",
			"Turban",
			"Veil",
			"Wig",
			"Wimple",
			"Wreath"
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
		mintItem(to, container, Items.HEAD, seed);
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.HEAD);
	}
}
