// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import './ITicket.sol';

contract Ticket is ERC721, EIP712, ERC721URIStorage, ITicket, Pausable, Ownable, ERC721Burnable, AccessControlEnumerable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

  constructor(string memory name, string memory symbol) ERC721(name, symbol) EIP712('DotocracyNFTVotes', 'v1') {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
  }

  modifier checkTransfer(address to) {
    _checkAdminRole();
    _checkReceiverBalance(to);
    _;
  }

  modifier checkMint(address to) {
    _checkMinterRole();
    _checkReceiverBalance(to);
    _;
  }

  function _checkMinterRole() internal view virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), 'TicketERC721: must have minter role to mint');
  }

  function _checkAdminRole() internal view virtual {
    require(hasRole(ADMIN_ROLE, _msgSender()), 'TicketERC721: must have admin role to transfer');
  }

  function _checkReceiverBalance(address to) internal view virtual {
    require(balanceOf(to) < 1, 'TicketERC721: receiver cannot own more than one Ballot Ticket');
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override(ERC721) {
    super._afterTokenTransfer(from, to, firstTokenId, batchSize);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function safeMint(address to) public virtual override checkMint(to) {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function burn(uint256 tokenId) public override {
    require(hasRole(BURNER_ROLE, _msgSender()), 'TicketERC721: must have burner role to burn');

    _burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721, IERC721) checkTransfer(to) {
    super._transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721, IERC721) checkTransfer(to) {
    super.safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override(ERC721, IERC721) checkTransfer(to) {
    super._safeTransfer(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
