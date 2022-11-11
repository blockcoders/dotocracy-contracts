// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

abstract contract ITicket is IERC721 {
  function safeMint(address to) public virtual;
}
