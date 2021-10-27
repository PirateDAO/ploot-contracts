// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootContainer } from "./ILootContainer.sol";

interface ILootItem is IERC721Enumerable, IERC721Permit {
	enum Items {
		FREE_SLOT,
		HEAD,
		NECK,
		CHEST,
		HANDS,
		LEGS,
		FEET,
		WEAPON,
		OFF_HAND
	}

	enum Rarity {
		UNKNOWN,
		COMMON,
		UNCOMMON,
		RARE,
		EPIC,
		LEGENDARY,
		MYTHIC,
		RELIC
	}

	struct Item {
		uint256 seed;
		uint8 index;
		uint8 appearance;
		uint8 prefix;
		uint8 suffix;
		uint8 augmentation;
		Rarity rarity;
	}

	event LootItemMinted(uint256 indexed id, Items item, Rarity rarity);

	function mint(
		address to,
		ILootContainer.Containers container,
		uint256 seed
	) external;

	function lootURI(uint256 id, Items itemType) external view returns (string memory);

	function lootSVG(
		uint256 id,
		Items itemType,
		bool single
	) external view returns (string memory);
}
