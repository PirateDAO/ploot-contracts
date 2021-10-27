// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { IGovernable } from "./IGovernable.sol";
import { ILootContainer } from "./ILootContainer.sol";

interface IProgrammableLoot is IGovernable {
	struct ContainerGenesis {
		ILootContainer.Containers container;
		uint256 containerId;
		uint256 genesisIndex;
		bytes32 requestId;
		address claimant;
		bool claimed;
		uint80 timestamp;
	}

	struct GenesisRequest {
		uint256 randomness;
	}

	event LootContainerClaimed(
		uint256 indexed id,
		ILootContainer.Containers container,
		uint256 randomness,
		address indexed claimant
	);
	event GenesisRequested(
		address indexed claimant,
		ILootContainer.Containers indexed container,
		bytes32 indexed requestId
	);
	event GenesisInflationChanged(uint16 oldInflation, uint16 newInflation);
	event ContainerFloorChanged(ILootContainer.Containers container, uint256 newFloor);
	event ChainlinkFeeChanged(uint256 oldFee, uint256 newFee);

	function getContainerGenesisFor(address claimant) external view returns (ContainerGenesis[] memory genesis);

	function getContainerPriceWithFee(ILootContainer.Containers container)
		external
		view
		returns (uint256 priceInEth, uint256 feeInEth);

	function generateContainerSeed(ILootContainer.Containers container) external payable returns (bytes32 requestId);

	function claimContainer(uint256 index) external;

	function rescueToken(IERC20 token) external;

	function setContainerFloor(ILootContainer.Containers container, uint256 floor) external;

	function setGenesisInflationGauge(uint16 inflation) external;

	function setChainlinkFee(uint256 linkFee) external;

	function toggleRewards() external;
}
