// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable quotes */

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { ILootItem } from "./interfaces/ILootItem.sol";
import { Base64 } from "./libraries/Base64.sol";
import { ERC721Base } from "./libraries/ERC721Base.sol";
import { Randomness } from "./libraries/Randomness.sol";

/// @author 0xBlackbeard
abstract contract LootItem is ERC721Base, Ownable, Randomness, ILootItem {
	using Strings for uint256;

	uint256 internal constant COMMON_CEILING = 80_87665e13;
	uint256 internal constant UNCOMMON_CEILING = 90_99999e13;
	uint256 internal constant RARE_CEILING = 96_65036e13;
	uint256 internal constant EPIC_CEILING = 99_65430e13;
	uint256 internal constant LEGENDARY_CEILING = 99_99200e13;
	uint256 internal constant MYTHIC_CEILING = 99_99965e13;
	uint256 internal constant RELIC_CEILING = 99_99995e13;

	mapping(uint256 => Item) public loot;

	string[] public items;

	string[] internal appearances = [
		"Ancient",
		"Blunt",
		"Colossal",
		"Corrupted",
		"Degraded",
		"Depleted",
		"Dusty",
		"Elite",
		"Enchanted",
		"Exquisite",
		"Fine",
		"Flawless",
		"Flimsy",
		"Giant",
		"Grand",
		"Great",
		"Greater",
		"Inferior",
		"Large",
		"Lesser",
		"Mighty",
		"Musky",
		"Noble",
		"Ornate",
		"Petty",
		"Polished",
		"Potent",
		"Rough",
		"Ruined",
		"Rusty",
		"Small",
		"Superior",
		"Ugly",
		"Unique"
	];

	string[] internal prefixes = [
		"Acrobat",
		"Agony",
		"Alchemical",
		"Alloy",
		"Alluring",
		"Aluminum",
		"Amazon",
		"Amber",
		"Antimony",
		"Anubis",
		"Apocalypse",
		"Apothecary",
		"Archer",
		"Arctic",
		"Armageddon",
		"Armorer",
		"Assassin",
		"Atlantean",
		"Avenger",
		"Barbarian",
		"Bard",
		"Basilisk",
		"Beastly",
		"Bedrock",
		"Behemoth",
		"Bishop",
		"Bismuth",
		"Blight",
		"Blood",
		"Botryoidal",
		"Bramble",
		"Brimstone",
		"Brood",
		"Calcite",
		"Cancer",
		"Carbon",
		"Carrion",
		"Cataclysm",
		"Celtic",
		"Centaur",
		"Cerberus",
		"Chainmail",
		"Chameleon",
		"Chilling",
		"Chimera",
		"Chimeric",
		"Chronos",
		"Combusting",
		"Copper",
		"Corpse",
		"Crusader",
		"Crystal",
		"Cursed",
		"Death",
		"Demon",
		"Demonic",
		"Devotion",
		"Devouring",
		"Diamond",
		"Dire",
		"Disciple",
		"Disease",
		"Divine",
		"Doom",
		"Draconian",
		"Dragon",
		"Dread",
		"Druid",
		"Dusk",
		"Dwarven",
		"Eagle",
		"Earthly",
		"Ebony",
		"Eden",
		"Elder",
		"Elemental",
		"Elven",
		"Ember",
		"Empyrean",
		"Ethereal",
		"Executioner's",
		"Fair",
		"Fate",
		"Feather",
		"Feral",
		"Flame",
		"Fluorite",
		"Foe",
		"Fossil",
		"Frost",
		"Fur",
		"Gale",
		"Gallic",
		"Garnet",
		"Genesis",
		"Ghastly",
		"Ghoul",
		"Glacier",
		"Glass",
		"Gleam",
		"Gloom",
		"Glowing",
		"Glyph",
		"Goblin",
		"Golden",
		"Golem",
		"Griffin",
		"Grim",
		"Harpy",
		"Hate",
		"Havoc",
		"Healer",
		"Herald",
		"Hollow",
		"Holy",
		"Honour",
		"Horror",
		"Hunt",
		"Hunting",
		"Hydra",
		"Hypnotic",
		"Imperial",
		"Incandescent",
		"Iridescent",
		"Iron",
		"Jade",
		"Juggernaut",
		"Keeper",
		"Knight",
		"Kraken",
		"Lead",
		"Leather",
		"Legion",
		"Light",
		"Loath",
		"Lust",
		"Madness",
		"Maelstrom",
		"Mage",
		"Malevolence",
		"Mandrake",
		"Manticore",
		"Martyrdom",
		"Merchant's",
		"Mercury",
		"Metallic",
		"Meteorite",
		"Mind",
		"Minion",
		"Minotaur",
		"Miracle",
		"Molding",
		"Monk",
		"Morbid",
		"Mutagen",
		"Mutant",
		"Mystic",
		"Necromancer",
		"Nickel",
		"Night-Eye",
		"Oblivion",
		"Obsidian",
		"Oganesson",
		"Ogre",
		"Olympian",
		"Onslaught",
		"Opal",
		"Orcish",
		"Osiris",
		"Pain",
		"Pandemonium",
		"Pangolin",
		"Phoenix",
		"Pilgrim",
		"Pirate",
		"Plague",
		"Platinum",
		"Poison",
		"Porous",
		"Rage",
		"Ragnarok",
		"Ramming",
		"Rapture",
		"Raven",
		"Reaper",
		"Relic",
		"Relict",
		"Rogue",
		"Royal",
		"Rune",
		"Ruthless",
		"Sailor",
		"Samurai",
		"Savage",
		"Saviour",
		"Scourge",
		"Scout",
		"Scribe",
		"Sentient",
		"Shade",
		"Shadow",
		"Shimmering",
		"Shivering",
		"Silent",
		"Silver",
		"Skull",
		"Snakeskin",
		"Sneak",
		"Solstice",
		"Sorcerer",
		"Sorrow",
		"Soul",
		"Spectre",
		"Sphinx",
		"Spirit",
		"Sponge",
		"Spring",
		"Stalwart",
		"Steel",
		"Stone",
		"Storm",
		"Sunken",
		"Swamp",
		"Sylvan",
		"Tempest",
		"Thief",
		"Titan",
		"Titanium",
		"Topaz",
		"Torment",
		"Tourmaline",
		"Treacherous",
		"Troll",
		"Ursine",
		"Valkyrie",
		"Vampire",
		"Vengeance",
		"Venom",
		"Vermilion",
		"Vesper",
		"Victory",
		"Viking",
		"Viper",
		"Vortex",
		"Vulcan",
		"Warrior",
		"Water",
		"Whispering",
		"Witch",
		"Witch-hunter",
		"Woe",
		"Wooden",
		"Worms'",
		"Wrath",
		"Xeon",
		"Zealot"
	];

	string[] internal suffixes = [
		"of Abatement",
		"of Abhorrence",
		"of Aggression",
		"of Agility",
		"of Alteration",
		"of Amelioration",
		"of Anger",
		"of Animosity",
		"of Annihilation",
		"of Beguilement",
		"of Brilliance",
		"of Caress",
		"of Carnage",
		"of Castration",
		"of Charm",
		"of Clarity",
		"of Conjuration",
		"of Coping",
		"of Corruption",
		"of Creation",
		"of Damnation",
		"of Decay",
		"of Deflection",
		"of Depletion",
		"of Destruction",
		"of Detection",
		"of Detonation",
		"of Disbelief",
		"of Discipline",
		"of Disease",
		"of Doom",
		"of Dread",
		"of Elation",
		"of Encumbrance",
		"of Endurance",
		"of Enlightenment",
		"of Eruption",
		"of Eternity",
		"of Evasion",
		"of Extermination",
		"of Fairness",
		"of Faith",
		"of Fire",
		"of Folks",
		"of Fortitude",
		"of Freedom",
		"of Frost",
		"of Fury",
		"of Giants",
		"of Greed",
		"of Hatred",
		"of Holiness",
		"of Honesty",
		"of Illusion",
		"of Immolation",
		"of Immunity",
		"of Incredulity",
		"of Infection",
		"of Infliction",
		"of Influx",
		"of Inhibition",
		"of Invigoration",
		"of Invincibility",
		"of Languor",
		"of Lava",
		"of Levitation",
		"of Levity",
		"of Love",
		"of Mages",
		"of Mysticism",
		"of Negligence",
		"of Night-eye",
		"of Nullification",
		"of Numbing",
		"of Paralysis",
		"of Perfection",
		"of Personality",
		"of Placation",
		"of Poison",
		"of Possession",
		"of Power",
		"of Promiscuity",
		"of Propagation",
		"of Protection",
		"of Purity",
		"of Rage",
		"of Reciprocity",
		"of Reflection",
		"of Refusal",
		"of Replenishment",
		"of Resilience",
		"of Restoration",
		"of Retribution",
		"of Righteousness",
		"of Sand",
		"of Severance",
		"of Shock",
		"of Slumber",
		"of Sneaking",
		"of Speech",
		"of Speed",
		"of Stamina",
		"of Starvation",
		"of Storms",
		"of Symbiosis",
		"of Tempest",
		"of Tenderness",
		"of Thieving",
		"of Titans",
		"of Torture",
		"of Transmutation",
		"of Treachery",
		"of Ugliness",
		"of Usurpation",
		"of Vengeance",
		"of Vitriol",
		"of Warding",
		"of Water-breathing",
		"of Welding",
		"of Wonder",
		"of the Abyss",
		"of the Academic",
		"of the Acrobat",
		"of the Alchemist",
		"of the Apothecary",
		"of the Apotheosis",
		"of the Apprentice",
		"of the Arachnids",
		"of the Arcane",
		"of the Arch-mage",
		"of the Archer",
		"of the Artisan",
		"of the Ashes",
		"of the Assassin",
		"of the Bandit",
		"of the Bane",
		"of the Bard",
		"of the Basilisk",
		"of the Bear",
		"of the Beast",
		"of the Blizzard",
		"of the Boar",
		"of the Buccaneer",
		"of the Captive",
		"of the Cave",
		"of the Citadel",
		"of the Colossus",
		"of the Craft",
		"of the Crown",
		"of the Crusader",
		"of the Crypt",
		"of the Curse",
		"of the Cyclops",
		"of the Dawn",
		"of the Depths",
		"of the Desert",
		"of the Despicable",
		"of the Divine",
		"of the Dragon",
		"of the Drowned",
		"of the Druid",
		"of the Elder",
		"of the Elements",
		"of the Fall",
		"of the Fallen",
		"of the Feline",
		"of the Fish",
		"of the Flagellant",
		"of the Flow",
		"of the Forge",
		"of the Fox",
		"of the Gargoyles",
		"of the Genesis",
		"of the Glacier",
		"of the Gorgon",
		"of the Harpies",
		"of the Healer",
		"of the Herald",
		"of the Hive",
		"of the Hunt",
		"of the Inquisitor",
		"of the Island",
		"of the Jarl",
		"of the Jester",
		"of the Knight",
		"of the Kraken",
		"of the Labyrinth",
		"of the Lady",
		"of the Lair",
		"of the Legion",
		"of the Lover",
		"of the Mage",
		"of the Magician",
		"of the Mandrake",
		"of the Martyr",
		"of the Mere",
		"of the Mermaid",
		"of the Meteorite",
		"of the Mine",
		"of the Monarch",
		"of the Monk",
		"of the Mountain",
		"of the Necromancer",
		"of the Night",
		"of the North",
		"of the Ocean",
		"of the Ogres",
		"of the Oracle",
		"of the Orcs",
		"of the Pangolin",
		"of the Pariah",
		"of the Pharaoh",
		"of the Phoenix",
		"of the Pilgrim",
		"of the Plague",
		"of the Plains",
		"of the Priest",
		"of the Princess",
		"of the Prophet",
		"of the Rats",
		"of the Raven",
		"of the Reaper",
		"of the River",
		"of the Rogue",
		"of the Sage",
		"of the Scales",
		"of the Scout",
		"of the Sea",
		"of the Sentinel",
		"of the Serpent",
		"of the Shadows",
		"of the Shepherd",
		"of the Shrine",
		"of the Sorcerer",
		"of the Steed",
		"of the Storm",
		"of the Swamp",
		"of the Sybil",
		"of the Thief",
		"of the Tower",
		"of the Trolls",
		"of the Twins",
		"of the Undead",
		"of the Unknown",
		"of the Vampire",
		"of the Void",
		"of the Volcano",
		"of the Warrior",
		"of the Water",
		"of the Well",
		"of the Whale",
		"of the Will",
		"of the Wizard",
		"of the Wolf",
		"of the Woods",
		"of the Worms"
	];

	constructor(string memory name, string memory symbol) ERC721Base(name, symbol) {} // solhint-disable-line no-empty-blocks

	function mintItem(
		address to,
		ILootContainer.Containers container,
		Items item,
		uint256 seed
	) internal virtual {
		uint256 id = totalSupply() + 1;
		_safeMint(to, id);
		loot[id].seed = seed;

		uint256 lootIndex = (uint256(keccak256(abi.encode(seed, items.length))) % 100e18) % items.length;
		loot[id].index = uint8(lootIndex);

		Rarity rarity = whatRarity(container, item, seed);
		loot[id].rarity = rarity;
		loot[id].appearance = whatAppearance(item, rarity, seed);
		loot[id].prefix = whichPrefix(item, rarity, seed);
		loot[id].suffix = whichSuffix(item, rarity, seed);
		loot[id].augmentation = whichAugmentation(item, rarity, seed);

		emit LootItemMinted(id, item, rarity);
	}

	function whatRarity(
		ILootContainer.Containers container,
		Items item,
		uint256 seed
	) internal view virtual returns (Rarity) {
		uint256 chance = uint256(keccak256(abi.encode(seed, container, item, totalSupply()))) % 100e18;

		if (container == ILootContainer.Containers.SACK) {
			if (chance > EPIC_CEILING) {
				if (chance % 2 != 1) chance -= chance % (1e17);
			}
		}

		if (container == ILootContainer.Containers.BARREL || container == ILootContainer.Containers.CRATE) {
			if (chance < COMMON_CEILING) chance += chance % (12 * 1e18);
		}

		if (container == ILootContainer.Containers.URN || container == ILootContainer.Containers.COFFER) {
			if (chance < COMMON_CEILING) chance += chance % (16 * 1e18);
			if (chance < UNCOMMON_CEILING) chance += chance % (8 * 1e18);
		}

		if (container == ILootContainer.Containers.CHEST) {
			if (chance < COMMON_CEILING) chance += chance % (18 * 1e18);
			if (chance < UNCOMMON_CEILING) chance += chance % (9 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (3 * 1e18);
		}

		if (container == ILootContainer.Containers.TROVE) {
			if (chance < COMMON_CEILING) chance += chance % (20 * 1e18);
			else if (chance < UNCOMMON_CEILING) chance += chance % (12 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (5 * 1e18);
		}

		if (container == ILootContainer.Containers.RELIQUARY) {
			if (chance < COMMON_CEILING) chance += chance % (25 * 1e18);
			else if (chance < UNCOMMON_CEILING) chance += chance % (15 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (7 * 1e18);
		}

		if (chance <= COMMON_CEILING) return Rarity.COMMON;
		else if (chance <= UNCOMMON_CEILING) return Rarity.UNCOMMON;
		else if (chance <= RARE_CEILING) return Rarity.RARE;
		else if (chance <= EPIC_CEILING) return Rarity.EPIC;
		else if (chance <= LEGENDARY_CEILING) return Rarity.LEGENDARY;
		else if (chance <= MYTHIC_CEILING) return Rarity.MYTHIC;
		else if (chance >= RELIC_CEILING) return Rarity.RELIC;
		else return Rarity.UNKNOWN;
	}

	function whatAppearance(
		Items item,
		Rarity rarity,
		uint256 seed
	) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(seed, item, rarity, appearances.length))) % 100e18;

		if (rarity >= Rarity.UNCOMMON) {
			return uint8(chance % appearances.length);
		}

		return 0;
	}

	function whichPrefix(
		Items item,
		Rarity rarity,
		uint256 seed
	) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(seed, item, rarity, prefixes.length))) % 100e18;

		if (rarity >= Rarity.RARE) {
			return uint8(chance % prefixes.length);
		}

		return 0;
	}

	function whichSuffix(
		Items item,
		Rarity rarity,
		uint256 seed
	) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(seed, item, rarity, suffixes.length))) % 100e18;

		if (rarity >= Rarity.EPIC) {
			return uint8(chance % suffixes.length);
		}

		return 0;
	}

	function whichAugmentation(
		Items item,
		Rarity rarity,
		uint256 seed
	) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(seed, item, rarity, 10))) % 100e18;

		if (rarity == Rarity.LEGENDARY) {
			return uint8((chance % 5) + 1);
		} else if (rarity == Rarity.MYTHIC) {
			return uint8((chance % 4) + 6);
		} else if (rarity == Rarity.RELIC) {
			return 10;
		}

		return 0;
	}

	// solhint-disable-next-line no-unused-vars
	function tokenURI(uint256 id) public view virtual override returns (string memory) {
		revert("LootItem::tokenURI: not implemented"); // solhint-disable-line reason-string
	}

	function lootURI(uint256 id, Items itemType) public view virtual override returns (string memory) {
		string[3] memory parts;
		parts[0] = string(
			abi.encodePacked(
				'<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 480 40">',
				"<style>.ploot__base { font-family: serif; font-size: 14px; }",
				".ploot__common { fill: #FFFFFF; }",
				".ploot__uncommon { fill: #DDDDDD; }",
				".ploot__rare { fill: #0088ff; }",
				".ploot__epic { fill: #01FF70; }",
				".ploot__legendary { fill: #FFDD00; }",
				".ploot__mythic { fill: #EB00FF; }",
				".ploot__relic { fill: #FF0099; }</style>",
				'<rect width="100%" height="100%" fill="#000" />'
			)
		);
		parts[1] = lootSVG(id, itemType, true);
		parts[2] = "</svg>";

		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

		string memory itemName;
		if (itemType == Items.HEAD) itemName = '{"name": "Head #';
		else if (itemType == Items.NECK) itemName = '{"name": "Neck #';
		else if (itemType == Items.CHEST) itemName = '{"name": "Chest #';
		else if (itemType == Items.HANDS) itemName = '{"name": "Hands #';
		else if (itemType == Items.LEGS) itemName = '{"name": "Legs #';
		else if (itemType == Items.FEET) itemName = '{"name": "Feet #';
		else if (itemType == Items.WEAPON) itemName = '{"name": "Weapon #';
		else if (itemType == Items.OFF_HAND) itemName = '{"name": "Off-hand #';

		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						itemName,
						id.toString(),
						'", "description": "Programmable Loot is economically scarce and verifiably randomized loot metadata generated and stored on-chain. Maximum supply is dynamic, originally increasing at 1/10th of Ethereum\'s block rate. Stats, images, and other functionality are omitted for others to interpret. Rarity is probabilistically determined at genesis time. Loot is programmable as items can be exchanged across containers at any time", "image": "data:image/svg+xml;base64,',
						Base64.encode(bytes(output)),
						'"}'
					)
				)
			)
		);
		output = string(abi.encodePacked("data:application/json;base64,", json));

		return output;
	}

	function lootSVG(
		uint256 id,
		Items itemType,
		bool single
	) public view virtual override returns (string memory) {
		if (id == 0) return "";
		if (id > totalSupply()) revert("LootItem::lootSVG: invalid item id"); // solhint-disable-line reason-string
		Item memory item = loot[id];

		string memory output;
		string memory class;
		if (item.rarity == Rarity.COMMON) {
			output = string(abi.encodePacked(items[item.index]));
			class = 'class="ploot__base ploot__common"';
		} else if (item.rarity == Rarity.UNCOMMON) {
			output = string(abi.encodePacked(appearances[item.appearance], " ", items[item.index]));
			class = 'class="ploot__base ploot__uncommon"';
		} else if (item.rarity == Rarity.RARE) {
			output = string(
				abi.encodePacked(appearances[item.appearance], " ", prefixes[item.prefix], " ", items[item.index])
			);
			class = 'class="ploot__base ploot__rare"';
		} else if (item.rarity == Rarity.EPIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix]
				)
			);
			class = 'class="ploot__base ploot__epic"';
		} else if (item.rarity == Rarity.LEGENDARY) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					uint256(item.augmentation).toString()
				)
			);
			class = 'class="ploot__base ploot__legendary"';
		} else if (item.rarity == Rarity.MYTHIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					uint256(item.augmentation).toString()
				)
			);
			class = 'class="ploot__base ploot__mythic"';
		} else if (item.rarity == Rarity.RELIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					uint256(item.augmentation).toString()
				)
			);
			class = 'class="ploot__base ploot__relic"';
		}

		string memory y;
		if (single) y = 'y="25"';
		else if (itemType == Items.HEAD) y = 'y="25"';
		else if (itemType == Items.NECK) y = 'y="50"';
		else if (itemType == Items.CHEST) y = 'y="75"';
		else if (itemType == Items.HANDS) y = 'y="100"';
		else if (itemType == Items.LEGS) y = 'y="125"';
		else if (itemType == Items.FEET) y = 'y="150"';
		else if (itemType == Items.WEAPON) y = 'y="175"';
		else if (itemType == Items.OFF_HAND) y = 'y="200"';

		return string(abi.encodePacked('<text x="15" ', y, " ", class, ">", output, "</text>"));
	}
}
