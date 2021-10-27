// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable quotes, reason-string */

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { ILootItem } from "./interfaces/ILootItem.sol";
import { Base64 } from "./libraries/Base64.sol";
import { ERC721Base } from "./libraries/ERC721Base.sol";
import { Randomness } from "./libraries/Randomness.sol";

/// @author 0xBlackbeard
contract LootContainer is ERC721Base, ERC721Holder, Randomness, Ownable, ILootContainer {
	using Strings for uint256;

	mapping(uint256 => Container) public containers;
	mapping(ILootItem.Items => ILootItem) public items;
	mapping(uint256 => mapping(ILootItem.Items => uint256)) public loot;

	constructor(
		ILootItem head,
		ILootItem neck,
		ILootItem chest,
		ILootItem hands,
		ILootItem legs,
		ILootItem feet,
		ILootItem weapon,
		ILootItem off_hand // solhint-disable-line var-name-mixedcase
	) ERC721Base("Programmable Loot", "pLOOT") {
		items[ILootItem.Items.HEAD] = head;
		items[ILootItem.Items.NECK] = neck;
		items[ILootItem.Items.CHEST] = chest;
		items[ILootItem.Items.HANDS] = hands;
		items[ILootItem.Items.LEGS] = legs;
		items[ILootItem.Items.FEET] = feet;
		items[ILootItem.Items.WEAPON] = weapon;
		items[ILootItem.Items.OFF_HAND] = off_hand;
	}

	function mint(
		address to,
		Containers container,
		uint256 seed
	) external override onlyOwner returns (uint256 id) {
		id = totalSupply() + 1;
		_safeMint(to, id);

		uint256 obfuscatedSeed = weakSeed(seed);
		containers[id] = Container(container, obfuscatedSeed, uint80(block.timestamp)); // solhint-disable-line not-rely-on-time

		uint8 item = uint8(type(ILootItem.Items).min) + 1;
		while (item <= uint8(type(ILootItem.Items).max)) {
			if (isItemInside(container, ILootItem.Items(item), obfuscatedSeed)) {
				ILootItem lootItemInterface = items[ILootItem.Items(item)];
				lootItemInterface.mint(address(this), container, obfuscatedSeed);
				loot[id][ILootItem.Items(item)] = lootItemInterface.totalSupply();
			}
			item++;
		}

		emit LootContainerMinted(id, container, obfuscatedSeed, to);
	}

	function withdraw(
		uint256 containerId,
		ILootItem.Items item,
		address to
	) public override {
		require(
			_isApprovedOrOwner(msg.sender, containerId),
			"LootContainer::withdraw: caller not allowed to withdraw items"
		);

		uint256 itemId = loot[containerId][ILootItem.Items(item)];
		require(itemId != uint8(ILootItem.Items.FREE_SLOT), "LootContainer::withdraw: non-existent item");

		ILootItem lootItemInterface = items[item];
		lootItemInterface.safeTransferFrom(address(this), to, itemId);
		loot[containerId][item] = uint8(ILootItem.Items.FREE_SLOT);

		emit LootWithdrawn(containerId, item, itemId);
	}

	function withdrawAll(uint256 containerId, address to) external override {
		require(
			_isApprovedOrOwner(msg.sender, containerId),
			"LootContainer::withdrawAll: caller not allowed to withdraw items"
		);
		uint8 withdrawals = 0;
		uint8 item = uint8(type(ILootItem.Items).min) + 1;
		while (item <= uint8(type(ILootItem.Items).max)) {
			uint256 itemId = loot[containerId][ILootItem.Items(item)];
			if (itemId != uint8(ILootItem.Items.FREE_SLOT)) {
				ILootItem lootItemInterface = items[ILootItem.Items(item)];
				lootItemInterface.safeTransferFrom(address(this), to, itemId);
				loot[containerId][ILootItem.Items(item)] = uint8(ILootItem.Items.FREE_SLOT);

				emit LootWithdrawn(containerId, ILootItem.Items(item), itemId);
				withdrawals++;
			}
			item++;
		}
		require(withdrawals > 0, "LootContainer::withdrawAll: empty container");
	}

	function deposit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId
	) public override {
		require(
			_isApprovedOrOwner(msg.sender, containerId),
			"LootContainer::deposit: caller not allowed to deposit items"
		);

		uint256 currentItemId = loot[containerId][item];
		ILootItem lootItemInterface = items[item];
		address ownerOfItem = lootItemInterface.ownerOf(itemId);

		if (currentItemId != uint8(ILootItem.Items.FREE_SLOT)) withdraw(containerId, item, ownerOfItem);
		lootItemInterface.safeTransferFrom(ownerOfItem, address(this), itemId);
		loot[containerId][item] = itemId;

		emit LootDeposited(containerId, item, itemId);
	}

	function depositWithPermit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override {
		ILootItem lootItemInterface = items[item];
		lootItemInterface.permit(address(this), itemId, block.number, v, r, s);
		deposit(containerId, item, itemId);
	}

	function tokenURI(uint256 id) public view override returns (string memory) {
		Container memory container = containers[id];
		require(container.timestamp != 0, "LootContainer::tokenURI: non-existent container");

		string[9] memory parts;

		string memory background = "#FFFFFF";
		if (container.class == Containers.SACK) background = "#242424";
		else if (container.class == Containers.BARREL) background = "#1a1111";
		else if (container.class == Containers.CRATE) background = "#170e00";
		else if (container.class == Containers.URN) background = "#171700";
		else if (container.class == Containers.COFFER) background = "#100c10";
		else if (container.class == Containers.CHEST) background = "#170000";
		else if (container.class == Containers.TROVE) background = "#000e00";
		else if (container.class == Containers.RELIQUARY) background = "#240024";
		string memory rect = string(abi.encodePacked('<rect width="100%" height="100%" fill="', background, '" />'));

		parts[0] = string(
			abi.encodePacked(
				'<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 480 220">',
				"<style>.ploot__base { font-family: serif; font-size: 14px; }",
				".ploot__common { fill: #FFFFFF; }",
				".ploot__uncommon { fill: #DDDDDD; }",
				".ploot__rare { fill: #0088ff; }",
				".ploot__epic { fill: #01FF70; }",
				".ploot__legendary { fill: #FFDD00; }",
				".ploot__mythic { fill: #EB00FF; }",
				".ploot__relic { fill: #FF0099; }</style>",
				rect
			)
		);

		parts[1] = items[ILootItem.Items.HEAD].lootSVG(loot[id][ILootItem.Items.HEAD], ILootItem.Items.HEAD, false);
		parts[2] = items[ILootItem.Items.NECK].lootSVG(loot[id][ILootItem.Items.NECK], ILootItem.Items.NECK, false);
		parts[3] = items[ILootItem.Items.CHEST].lootSVG(loot[id][ILootItem.Items.CHEST], ILootItem.Items.CHEST, false);
		parts[4] = items[ILootItem.Items.HANDS].lootSVG(loot[id][ILootItem.Items.HANDS], ILootItem.Items.HANDS, false);
		parts[5] = items[ILootItem.Items.LEGS].lootSVG(loot[id][ILootItem.Items.LEGS], ILootItem.Items.LEGS, false);
		parts[6] = items[ILootItem.Items.FEET].lootSVG(loot[id][ILootItem.Items.FEET], ILootItem.Items.FEET, false);
		parts[7] = items[ILootItem.Items.WEAPON].lootSVG(loot[id][ILootItem.Items.WEAPON], ILootItem.Items.WEAPON, false);
		parts[8] = items[ILootItem.Items.OFF_HAND].lootSVG(
			loot[id][ILootItem.Items.OFF_HAND],
			ILootItem.Items.OFF_HAND,
			false
		);

		string memory output = string(
			abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
		);
		output = string(abi.encodePacked(output, "</svg>"));

		string memory containerName;
		if (container.class == Containers.SACK) containerName = '{"name": "Sack #';
		else if (container.class == Containers.BARREL) containerName = '{"name": "Barrel #';
		else if (container.class == Containers.CRATE) containerName = '{"name": "Crate #';
		else if (container.class == Containers.URN) containerName = '{"name": "Urn #';
		else if (container.class == Containers.COFFER) containerName = '{"name": "Coffer #';
		else if (container.class == Containers.CHEST) containerName = '{"name": "Chest #';
		else if (container.class == Containers.TROVE) containerName = '{"name": "Trove #';
		else if (container.class == Containers.RELIQUARY) containerName = '{"name": "Reliquary #';
		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						containerName,
						id.toString(),
						'", "description": "Programmable Loot is economically scarce and verifiably randomized loot metadata generated and stored on-chain. Maximum supply is dynamic, originally increasing at 1/10th of Ethereum\'s block rate. Stats, images, and other functionality are omitted for others to interpret. Rarity is probabilistically determined at genesis time. Loot items are programmable and exchangeable across containers at any time", "image": "data:image/svg+xml;base64,',
						Base64.encode(bytes(output)),
						'"}'
					)
				)
			)
		);
		output = string(abi.encodePacked("data:application/json;base64,", json));

		return output;
	}

	function isItemInside(
		Containers container,
		ILootItem.Items item,
		uint256 randomness
	) internal view returns (bool) {
		uint256 chance = (uint256(keccak256(abi.encode(randomness, container, item, totalSupply()))) % 100e18);

		if (container == Containers.SACK) {
			if (item == ILootItem.Items.HEAD) return chance > 91e18;
			if (item == ILootItem.Items.NECK) return chance > 99e18;
			if (item == ILootItem.Items.CHEST) return chance > 97e18;
			if (item == ILootItem.Items.HANDS) return chance > 93e18;
			if (item == ILootItem.Items.LEGS) return chance > 94e18;
			if (item == ILootItem.Items.FEET) return chance > 92e18;
			if (item == ILootItem.Items.WEAPON) return chance > 90e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 91e18;
		}

		if (container == Containers.BARREL) {
			if (item == ILootItem.Items.HEAD) return chance > 74e18;
			if (item == ILootItem.Items.NECK) return chance > 97e18;
			if (item == ILootItem.Items.CHEST) return chance > 88e18;
			if (item == ILootItem.Items.HANDS) return chance > 80e18;
			if (item == ILootItem.Items.LEGS) return chance > 87e18;
			if (item == ILootItem.Items.FEET) return chance > 78e18;
			if (item == ILootItem.Items.WEAPON) return chance > 77e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 76e18;
		}

		if (container == Containers.CRATE) {
			if (item == ILootItem.Items.HEAD) return chance > 72e18;
			if (item == ILootItem.Items.NECK) return chance > 94e18;
			if (item == ILootItem.Items.CHEST) return chance > 86e18;
			if (item == ILootItem.Items.HANDS) return chance > 74e18;
			if (item == ILootItem.Items.LEGS) return chance > 84e18;
			if (item == ILootItem.Items.FEET) return chance > 77e18;
			if (item == ILootItem.Items.WEAPON) return chance > 74e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 75e18;
		}

		if (container == Containers.URN) {
			if (item == ILootItem.Items.HEAD) return chance > 68e18;
			if (item == ILootItem.Items.NECK) return chance > 36e18;
			if (item == ILootItem.Items.CHEST) return chance > 98e18;
			if (item == ILootItem.Items.HANDS) return chance > 68e18;
			if (item == ILootItem.Items.LEGS) return chance > 96e18;
			if (item == ILootItem.Items.FEET) return chance > 70e18;
			if (item == ILootItem.Items.WEAPON) return chance > 75e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 71e18;
		}

		if (container == Containers.COFFER) {
			if (item == ILootItem.Items.HEAD) return chance > 64e18;
			if (item == ILootItem.Items.NECK) return chance > 60e18;
			if (item == ILootItem.Items.CHEST) return chance > 74e18;
			if (item == ILootItem.Items.HANDS) return chance > 68e18;
			if (item == ILootItem.Items.LEGS) return chance > 72e18;
			if (item == ILootItem.Items.FEET) return chance > 66e18;
			if (item == ILootItem.Items.WEAPON) return chance > 55e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 50e18;
		}

		if (container == Containers.CHEST) {
			if (item == ILootItem.Items.HEAD) return chance > 60e18;
			if (item == ILootItem.Items.NECK) return chance > 60e18;
			if (item == ILootItem.Items.CHEST) return chance > 60e18;
			if (item == ILootItem.Items.HANDS) return chance > 60e18;
			if (item == ILootItem.Items.LEGS) return chance > 60e18;
			if (item == ILootItem.Items.FEET) return chance > 60e18;
			if (item == ILootItem.Items.WEAPON) return chance > 60e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 60e18;
		}

		if (container == Containers.TROVE) {
			if (item == ILootItem.Items.HEAD) return chance > 70e18;
			if (item == ILootItem.Items.NECK) return chance > 55e18;
			if (item == ILootItem.Items.CHEST) return chance > 80e18;
			if (item == ILootItem.Items.HANDS) return chance > 70e18;
			if (item == ILootItem.Items.LEGS) return chance > 75e18;
			if (item == ILootItem.Items.FEET) return chance > 70e18;
			if (item == ILootItem.Items.WEAPON) return chance > 65e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 60e18;
		}

		if (container == Containers.RELIQUARY) {
			if (item == ILootItem.Items.HEAD) return chance > 80e18;
			if (item == ILootItem.Items.NECK) return chance > 80e18;
			if (item == ILootItem.Items.CHEST) return chance > 80e18;
			if (item == ILootItem.Items.HANDS) return chance > 80e18;
			if (item == ILootItem.Items.LEGS) return chance > 80e18;
			if (item == ILootItem.Items.FEET) return chance > 80e18;
			if (item == ILootItem.Items.WEAPON) return chance > 80e18;
			if (item == ILootItem.Items.OFF_HAND) return chance > 80e18;
		}

		return false;
	}
}
