// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @author Paddy (https://ethereum.stackexchange.com/a/83577)
 */
library RevertReason {
	/**
	 * @dev Helper function to extract the revert message from a failed contract call.
	 * Note that when the returned data is malformed or not correctly abi-encoded then this call itself may fail
	 */
	function extract(bytes memory returnData) internal pure returns (string memory) {
		// If the length is less than 68, then the transaction failed silently (without a revert reason)
		if (returnData.length < 68) {
			return "RevertReason::extract: transaction reverted without a reason string";
		}
		// solhint-disable-next-line no-inline-assembly
		assembly {
			returnData := add(returnData, 0x04) // slice the func selector away
		}
		return abi.decode(returnData, (string)); // all that remains is the revert string
	}
}
