// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable reason-string */

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds enumerability of all the token ids
 * in the contract as well as all token ids owned by each account; along with some add-ons (i.e. permits)
 */
abstract contract ERC721Base is ERC721, EIP712, IERC721Enumerable, IERC721Permit {
	using Counters for Counters.Counter;

	// solhint-disable-next-line var-name-mixedcase
	bytes32 public constant override PERMIT_TYPEHASH =
		keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	// Array with all token ids, used for enumeration
	uint256[] private _allTokens;

	// Mapping from token id to position in the allTokens array
	mapping(uint256 => uint256) private _allTokensIndex;

	mapping(uint256 => Counters.Counter) private _nonces;

	/**
	 * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
	 *
	 * It's a good idea to use the same `name` that is defined as the ERC20 token name.
	 */
	constructor(string memory name, string memory symbol) ERC721(name, symbol) EIP712(name, "1") {} // solhint-disable-line no-empty-blocks

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	 */
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		require(index < ERC721.balanceOf(owner), "ERC721Base::tokenOfOwnerByIndex: owner index out of bounds");
		return _ownedTokens[owner][index];
	}

	function tokensOfOwner(address owner) public view returns (uint256[] memory) {
		uint256 tokensBalance = ERC721.balanceOf(owner);
		uint256[] memory ownedTokens = new uint256[](tokensBalance);

		if (tokensBalance > 0) {
			for (uint256 i = 0; i < tokensBalance; i++) {
				uint256 ownedToken = _ownedTokens[owner][i];
				ownedTokens[i] = ownedToken;
			}
		}

		return ownedTokens;
	}

	/**
	 * @dev See {IERC721Enumerable-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return _allTokens.length;
	}

	/**
	 * @dev See {IERC721Enumerable-tokenByIndex}.
	 */
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		require(index < totalSupply(), "ERC721Base::tokenByIndex: global index out of bounds");
		return _allTokens[index];
	}

	/**
	 * @notice Approve of a specific token ID for spending by spender via signature
	 * @param spender The account that is being approved
	 * @param tokenId The ID of the token that is being approved for spending
	 * @param deadline The deadline (timestamp) by which the call must be mined for the approval to succeed
	 * @param v The recovery byte of the signature
	 * @param r Half of the ECDSA signature pair
	 * @param s Half of the ECDSA signature pair
	 */
	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		require(block.timestamp <= deadline, "ERC721Base::permit: expired deadline"); // solhint-disable-line not-rely-on-time
		address owner = ownerOf(tokenId);
		require(spender != owner, "ERC721Base::permit: approval to current owner");

		bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, _useNonce(tokenId), deadline));
		bytes32 digest = _hashTypedDataV4(structHash);

		require(
			SignatureChecker.isValidSignatureNow(owner, digest, abi.encodePacked(r, s, v)),
			"ERC721Base::permit: unauthorized"
		);

		_approve(spender, tokenId);
	}

	/**
	 * @dev Returns the current nonce for `owner`. This value must be included whenever a new `permit` sig is crafted.
	 * Every successful call to {permit} increases ``owner``'s nonce by one. This prevents sig from being re-used
	 */
	function nonces(uint256 tokenId) public view virtual override returns (uint256) {
		return _nonces[tokenId].current();
	}

	function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
		return _isApprovedOrOwner(spender, tokenId);
	}

	/// @notice The domain separator used in the permit signature
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view override returns (bytes32) {
		return _domainSeparatorV4();
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting.
	 *
	 * Calling conditions:
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) {
			_addTokenToAllTokensEnumeration(tokenId);
		} else if (from != to) {
			_removeTokenFromOwnerEnumeration(from, tokenId);
		}

		if (to != from) {
			_addTokenToOwnerEnumeration(to, tokenId);
		}
	}

	/**
	 * @dev Private function to add a token to this extension's ownership-tracking data structures.
	 * @param to address representing the new owner of the given token ID
	 * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		uint256 length = ERC721.balanceOf(to);
		_ownedTokens[to][length] = tokenId;
		_ownedTokensIndex[tokenId] = length;
	}

	/**
	 * @dev Private function to add a token to this extension's token tracking data structures.
	 * @param tokenId uint256 ID of the token to be added to the tokens list
	 */
	function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
		_allTokensIndex[tokenId] = _allTokens.length;
		_allTokens.push(tokenId);
	}

	/**
	 * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
	 * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
	 * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
	 * This has O(1) time complexity, but alters the order of the _ownedTokens array.
	 * @param from address representing the previous owner of the given token ID
	 * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		// To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).
		uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
		uint256 tokenIndex = _ownedTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary
		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

			_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}

		// This also deletes the contents at the last position of the array
		delete _ownedTokensIndex[tokenId];
		delete _ownedTokens[from][lastTokenIndex];
	}

	/**
	 * @dev Consumes a nonce: return the current value and increment it
	 */
	function _useNonce(uint256 tokenId) internal virtual returns (uint256 current) {
		Counters.Counter storage nonce = _nonces[tokenId];
		current = nonce.current();
		nonce.increment();
	}
}
