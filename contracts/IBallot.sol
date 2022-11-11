// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract IBallot {
  enum ProposalState {
    Pending,
    Active,
    Canceled,
    Succeeded,
    Expired,
    Executed
  }

  /**
   * @dev Emitted when a proposal is created.
   */
  event ProposalCreated(
    uint256 proposalId,
    address proposer,
    address[] voters,
    string[] options,
    uint256 startBlock,
    uint256 endBlock,
    string description
  );

  /**
   * @dev Emitted when a proposal is canceled.
   */
  event ProposalCanceled(uint256 proposalId);

  /**
   * @dev Emitted when a proposal is executed.
   */
  event ProposalExecuted(uint256 proposalId);

  /**
   * @dev Emitted when a vote is cast.
   */
  event VoteCast(address indexed voter, uint256 proposalId);

  function createProposal(
    address[] memory voters,
    uint256 delay,
    uint256 period,
    string memory description,
    string[] memory options
  ) public virtual returns (uint256);

  function hashProposal(
    address[] memory voters,
    uint256 delay,
    uint256 period,
    bytes32 descriptionHash,
    string[] memory options
  ) public pure virtual returns (uint256);

  function castVote(uint256 proposalId, bytes32 option) public virtual;

  function state(uint256 proposalId) public view virtual returns (ProposalState);

  function _countVote(
    uint256 proposalId,
    address voter,
    bytes32 optionHash
  ) internal virtual;

  function getOptions(uint256 proposalId) public view virtual returns (bytes32[] memory, string[] memory);

  function proposalDescription(uint256 proposalId) public view virtual returns (string memory);

  function startsOn(uint256 proposalId) public view virtual returns (uint256);

  function endsOn(uint256 proposalId) public view virtual returns (uint256);

  function getProposals(address voter) public view virtual returns (uint256[] memory);

  function execute(uint256 proposalId) public payable virtual returns (uint256);

  function cancel(uint256 proposalId) public virtual returns (uint256);

  function progress(uint256 proposalId) public view virtual returns (uint256, uint256);

  function getResults(uint256 proposalId) public view virtual returns (string[] memory, uint256[] memory);
}
