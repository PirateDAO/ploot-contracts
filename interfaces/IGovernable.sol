// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

interface IGovernable {
	function governance() external view returns (address);

	function pendingGovernance() external view returns (address);

	function changeGovernance(address newGov) external;

	function acceptGovernance() external;

	function removeGovernance() external;
}
