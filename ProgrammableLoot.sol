// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable not-rely-on-time, reason-string, var-name-mixedcase */

import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import { IAugmentedSushiswapRouter } from "./interfaces/IAugmentedSushiswapRouter.sol";
import { IChainlinkPegSwap } from "./interfaces/IChainlinkPegSwap.sol";
import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { IProgrammableLoot } from "./interfaces/IProgrammableLoot.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import { Governable } from "./libraries/Governable.sol";
import { IBlackbeard } from "./interfaces/IBlackbeard.sol";
import { IJollyRoger } from "./interfaces/IJollyRoger.sol";

/// @author 0xBlackbeard
contract ProgrammableLoot is VRFConsumerBase, ReentrancyGuard, Governable, IProgrammableLoot {
	using Address for address payable;
	using SafeERC20 for IERC20;

	uint256 public constant RELIQUARY_MINT_FLOOR = 9 ether;
	uint256 public constant TROVE_MINT_FLOOR = 4 ether;
	uint256 public constant CHEST_MINT_FLOOR = 2 ether;
	uint256 public constant COFFER_MINT_FLOOR = 0.4 ether;
	uint256 public constant URN_MINT_FLOOR = 0.2 ether;
	uint256 public constant CRATE_MINT_FLOOR = 0.02 ether;
	uint256 public constant BARREL_MINT_FLOOR = 0.01 ether;
	uint256 public constant SACK_MINT_FLOOR = 0.001 ether;

	IJollyRoger public immutable JOLLY_ROGER;
	IBlackbeard public immutable BLACKBEARD;

	uint16 public genesisInflationGauge = 10;
	bool public areRewardsEnabled = true;

	IChainlinkPegSwap public immutable CHAINLINK_PEG_SWAP;
	AggregatorV3Interface public immutable CHAINLINK_ETH_LINK_FEED;
	bytes32 public CHAINLINK_VRF_KEY_HASH;
	uint256 public CHAINLINK_VRF_LINK_FEE;

	IERC20 public immutable WETH;
	IERC20 public immutable WLINK;
	IAugmentedSushiswapRouter public immutable SUSHISWAP_ROUTER;

	mapping(uint8 => uint256) public containerFloors;
	mapping(bytes32 => GenesisRequest) public genesisRequest;
	mapping(address => ContainerGenesis[]) public claimantGenesis;
	mapping(address => mapping(uint256 => ContainerGenesis)) public claimantGenesisIndex;

	ILootContainer public immutable CONTAINERS;

	constructor(
		ILootContainer containers,
		IJollyRoger jollyRoger,
		IBlackbeard blackbeard,
		address vrfCoordinator,
		address wrappedLinkToken,
		address linkToken,
		bytes32 vrfKeyHash,
		uint256 vrfFee,
		address linkEthFeed,
		address linkPegSwap,
		address sushiRouter,
		address weth
	) VRFConsumerBase(vrfCoordinator, linkToken) Governable() {
		CONTAINERS = containers;
		BLACKBEARD = blackbeard;
		JOLLY_ROGER = jollyRoger;

		CHAINLINK_VRF_KEY_HASH = vrfKeyHash;
		CHAINLINK_VRF_LINK_FEE = vrfFee;
		CHAINLINK_ETH_LINK_FEED = AggregatorV3Interface(linkEthFeed);
		CHAINLINK_PEG_SWAP = IChainlinkPegSwap(linkPegSwap);
		SUSHISWAP_ROUTER = IAugmentedSushiswapRouter(sushiRouter);
		WLINK = IERC20(wrappedLinkToken);
		WETH = IERC20(weth);

		containerFloors[uint8(ILootContainer.Containers.SACK)] = SACK_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.BARREL)] = BARREL_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.CRATE)] = CRATE_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.URN)] = URN_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.COFFER)] = COFFER_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.CHEST)] = CHEST_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.TROVE)] = TROVE_MINT_FLOOR;
		containerFloors[uint8(ILootContainer.Containers.RELIQUARY)] = RELIQUARY_MINT_FLOOR;

		uint8 container = uint8(type(ILootContainer.Containers).min);
		while (container < uint8(type(ILootContainer.Containers).max)) {
			require(containerFloors[container] * 2 <= containerFloors[container + 1]);
			container++;
		}
	}

	/**
	 * @notice Requests the latest oracle reading for safely establishing the ETH/LINK exchange rate
	 * @dev Can be used before calling the `generate` function to determine the correct `msg.value` payload
	 */
	function getContainerPriceWithFee(ILootContainer.Containers container)
		public
		view
		override
		returns (uint256 priceInEth, uint256 feeInEth)
	{
		(, int256 _price, , , ) = CHAINLINK_ETH_LINK_FEED.latestRoundData();
		feeInEth = (uint256(_price) * CHAINLINK_VRF_LINK_FEE * 2) / 1e18;
		priceInEth = containerFloors[uint8(container)] + feeInEth;
	}

	/// @notice View to allow for measuring and filtering all container genesis structs belonging to `claimant`
	function getContainerGenesisFor(address claimant) external view override returns (ContainerGenesis[] memory genesis) {
		genesis = claimantGenesis[claimant];
	}

	/**
	 * @notice Requests a new container genesis, asking the VRF oracle for a real random seed
	 * @dev If caller is a contract, then it should implement the native receive function for ETH refunds
	 */
	function generateContainerSeed(ILootContainer.Containers container)
		external
		payable
		override
		nonReentrant
		returns (bytes32 requestId)
	{
		require(
			CONTAINERS.totalSupply() <= (block.number / genesisInflationGauge) + 1,
			"ProgrammableLoot::generateContainerSeed: illegal container supply growth"
		);

		(uint256 priceInEth, uint256 feeInEth) = getContainerPriceWithFee(container);
		require(
			WETH.allowance(msg.sender, address(this)) >= priceInEth,
			"ProgrammableLoot::generateContainerSeed: wrapped ether allowance too low"
		);

		WETH.safeTransferFrom(msg.sender, address(this), priceInEth);

		if (LINK.balanceOf(address(this)) < CHAINLINK_VRF_LINK_FEE) {
			uint256 wethBalanceBefore = WETH.balanceOf(address(this));
			WETH.safeApprove(address(SUSHISWAP_ROUTER), 0);
			WETH.safeIncreaseAllowance(address(SUSHISWAP_ROUTER), feeInEth);

			address[] memory path = new address[](2);
			path[0] = address(WETH);
			path[1] = address(WLINK);
			SUSHISWAP_ROUTER.swapExactTokensForTokens(
				feeInEth,
				CHAINLINK_VRF_LINK_FEE,
				path,
				address(this),
				block.timestamp
			);
			require(
				WLINK.balanceOf(address(this)) >= CHAINLINK_VRF_LINK_FEE,
				"ProgrammableLoot::generateContainerSeed: fraudulent wrapped LINK balance"
			);

			WLINK.approve(address(CHAINLINK_PEG_SWAP), 0);
			WLINK.safeIncreaseAllowance(address(CHAINLINK_PEG_SWAP), CHAINLINK_VRF_LINK_FEE);
			CHAINLINK_PEG_SWAP.swap(CHAINLINK_VRF_LINK_FEE, address(WLINK), address(LINK));

			uint256 wethBalanceAfter = WETH.balanceOf(address(this));
			require(
				wethBalanceAfter == wethBalanceBefore - feeInEth,
				"ProgrammableLoot::generateContainerSeed: fraudulent ETH balance"
			);
		}

		require(
			LINK.balanceOf(address(this)) >= CHAINLINK_VRF_LINK_FEE,
			"ProgrammableLoot::generateContainerSeed: not enough LINK"
		);
		requestId = requestRandomness(CHAINLINK_VRF_KEY_HASH, CHAINLINK_VRF_LINK_FEE);

		ContainerGenesis memory genesis = ContainerGenesis(
			container,
			0, // 0 is not a valid LootContainer ID
			claimantGenesis[msg.sender].length,
			requestId,
			msg.sender,
			false,
			uint80(block.timestamp)
		);
		claimantGenesis[genesis.claimant].push(genesis);
		claimantGenesisIndex[genesis.claimant][genesis.genesisIndex] = genesis;
		genesisRequest[requestId] = GenesisRequest(0);

		emit GenesisRequested(msg.sender, container, requestId);
	}

	/**
	 * @notice Claims an old container genesis, assembling the loot items at runtime and minting the relative tokens
	 * @dev Should be called only after checking for random seed delivery from the VRF oracle by either checking against
	 * `claimantGenesis` array or more expeditiously with `genesisRequest` if in possession of the genesis' `requestId`
	 */
	function claimContainer(uint256 genesisIndex) external override nonReentrant {
		ContainerGenesis storage genesis = claimantGenesis[msg.sender][genesisIndex];
		ContainerGenesis storage indexedGenesis = claimantGenesisIndex[genesis.claimant][genesis.genesisIndex];
		require(!genesis.claimed, "ProgrammableLoot::fulfillRandomness: genesis already claimed!");
		require(genesisIndex == genesis.genesisIndex, "ProgrammableLoot::fulfillRandomness: malformed claim");
		require(msg.sender == genesis.claimant, "ProgrammableLoot::fulfillRandomness: illegal claim");

		GenesisRequest memory genReq = genesisRequest[genesis.requestId];
		require(genReq.randomness != 0, "ProgrammableLoot::fulfillRandomness: missing random seed");

		uint256 containerId = CONTAINERS.mint(msg.sender, genesis.container, genReq.randomness);
		genesis.containerId = containerId;
		genesis.claimed = true;
		indexedGenesis.containerId = containerId;
		indexedGenesis.claimed = true;

		emit LootContainerClaimed(genesis.containerId, genesis.container, genReq.randomness, genesis.claimant);

		if (areRewardsEnabled && BLACKBEARD.hasRole(keccak256("MINTER_ROLE"), address(this))) {
			uint256 jjReward = _calculateContainerReward(genesis.container);
			if (jjReward <= JOLLY_ROGER.mintable()) BLACKBEARD.sew(msg.sender, jjReward);
		}
	}

	function setContainerFloor(ILootContainer.Containers container, uint256 floor) external override onlyGovernance {
		require(uint8(container) < 3, "ProgrammableLoot::setContainerFloor: rarer containers floor is immutable");
		require(
			floor * 2 <= containerFloors[uint8(container) + 1],
			"ProgrammableLoot::setContainerFloor: floor is over half the next rarer"
		);

		if (container != ILootContainer.Containers.SACK) {
			require(floor > 0, "ProgrammableLoot::setContainerFloor: only sacks may be claimed for free");
		}

		containerFloors[uint8(container)] = floor;
		emit ContainerFloorChanged(container, floor);
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		GenesisRequest storage genesis = genesisRequest[requestId];
		require(randomness != 0, "ProgrammableLoot::fulfillRandomness: malformed genesis");
		require(genesis.randomness == 0, "ProgrammableLoot::fulfillRandomness: illegal genesis");
		genesis.randomness = randomness;
	}

	/**
	 * @notice Sets the new container genesis inflation rate
	 */
	function toggleRewards() external override onlyGovernance {
		areRewardsEnabled = !areRewardsEnabled;
	}

	/**
	 * @notice Sets the new container genesis inflation rate
	 */
	function setGenesisInflationGauge(uint16 gauge) external override onlyGovernance {
		require(gauge >= 1, "ProgrammableLoot::setLootInflation: rampant inflation");
		emit GenesisInflationChanged(genesisInflationGauge, gauge);
		genesisInflationGauge = gauge;
	}

	/**
	 * @notice Sets the new VRF coordinator key hash and LINK fee (paid to the VRF oracle, in bips)
	 */
	function setChainlinkFee(uint256 linkFee) external override onlyGovernance {
		emit ChainlinkFeeChanged(CHAINLINK_VRF_LINK_FEE, linkFee);
		CHAINLINK_VRF_LINK_FEE = linkFee;
	}

	function rescueToken(IERC20 token) external override nonReentrant onlyGovernance {
		if (address(this).balance > 0) {
			payable(msg.sender).sendValue(address(this).balance);
		}

		uint256 tokenBal = token.balanceOf(address(this));
		if (tokenBal > 0) {
			token.transfer(msg.sender, tokenBal);
		}
	}

	function _calculateContainerReward(ILootContainer.Containers container) internal returns (uint256) {
		if (container == ILootContainer.Containers.SACK) return 213333333333333;
		else if (container == ILootContainer.Containers.BARREL) return 2133333333333333;
		else if (container == ILootContainer.Containers.CRATE) return 4266666666666666;
		else if (container == ILootContainer.Containers.URN) return 10666666666666668;
		else if (container == ILootContainer.Containers.COFFER) return 21333333333333336;
		else if (container == ILootContainer.Containers.CHEST) return 53333333333333340;
		else if (container == ILootContainer.Containers.TROVE) return 200000000000000000;
		else if (container == ILootContainer.Containers.RELIQUARY) return 400000000000000000;
		else revert("ProgrammableLoot::_calculateContainerReward: unknown container");
	}
}
