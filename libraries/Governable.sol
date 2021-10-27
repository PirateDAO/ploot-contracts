// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable reason-string */

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { IGovernable } from "../interfaces/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a governance) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governance account will be the one that deploys the contract. This
 * can later be changed with {changeGovernance}.
 *
 * This module is used through inheritance. It will make available the modifier `onlyGovernance`,
 * which can be applied to your functions to restrict their use to the governance.
 */
abstract contract Governable is Context, IGovernable {
	address private _governance;
	address private _pendingGovernance;

	event GovernanceChanged(address indexed formerGov, address indexed newGov);

	/**
	 * @dev Initializes the contract setting the deployer as the initial governance.
	 */
	constructor() {
		address msgSender = _msgSender();
		_governance = msgSender;
		emit GovernanceChanged(address(0), msgSender);
	}

	/**
	 * @dev Throws if called by any account other than the governance.
	 */
	modifier onlyGovernance() {
		require(governance() == _msgSender(), "Governable::onlyGovernance: caller is not governance");
		_;
	}

	/**
	 * @dev Returns the address of the current governance.
	 */
	function governance() public view virtual override returns (address) {
		return _governance;
	}

	/**
	 * @dev Returns the address of the pending governance.
	 */
	function pendingGovernance() public view virtual override returns (address) {
		return _pendingGovernance;
	}

	/**
	 * @dev Begins the governance transfer handshake with a new account (`newGov`).
	 *
	 * Requirements:
	 *   - can only be called by the current governance
	 */
	function changeGovernance(address _newGov) public virtual override onlyGovernance {
		require(_newGov != address(0), "Governable::changeGovernance: new governance cannot be the zero address");
		_pendingGovernance = _newGov;
	}

	/**
	 * @dev Ends the governance transfer handshake that results in governance powers being handed to the caller
	 *
	 * Requirements:
	 *   - caller must be the pending governance address
	 */
	function acceptGovernance() external virtual override {
		require(_msgSender() == _pendingGovernance, "Governable::acceptGovernance: only pending governance can accept");
		emit GovernanceChanged(_governance, _pendingGovernance);
		_governance = _pendingGovernance;
		_pendingGovernance = address(0);
	}

	/**
	 * @dev Leaves the contract without governance. It will not be possible to call
	 * `onlyGovernance` functions anymore. Can only be called by the current governance.
	 *
	 * NOTE: Renouncing governance will leave the contract without an governance,
	 * thereby removing any functionality that is only available to the governance.
	 */
	function removeGovernance() public virtual override onlyGovernance {
		emit GovernanceChanged(_governance, address(0));
		_governance = address(0);
	}
}
