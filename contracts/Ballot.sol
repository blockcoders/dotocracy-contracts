// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Timers.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import './IBallot.sol';
import './ITicket.sol';

contract Ballot is Context, ERC165, EIP712, IBallot, IERC721Receiver {
  using SafeCast for uint256;
  using Timers for Timers.BlockNumber;

  struct ProposalData {
    bytes32 descriptionHash;
    mapping(address => bool) voters;
    bytes32[] options;
    Timers.BlockNumber voteStart;
    Timers.BlockNumber voteEnd;
    bool executed;
    bool canceled;
  }

  ITicket public immutable tokenAddress;

  string private _name;

  mapping(uint256 => ProposalData) private _proposals;

  mapping(uint256 => string) private _proposalDescriptions;

  mapping(uint256 => mapping(bytes32 => uint256)) private _proposalOptionVotes;

  uint256[] private _proposalIds;

  mapping(uint256 => mapping(bytes32 => string)) private _proposalOptionTexts;

  mapping(uint256 => mapping(address => bool)) private _proposalCastedVotes;

  mapping(uint256 => address[]) private _proposalVoters;

  mapping(address => uint256[]) private _voterProposalIds;

  constructor(ITicket tokenAddress_, string memory name_) EIP712(name_, version()) {
    _name = name_;
    tokenAddress = tokenAddress_;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function version() public view virtual returns (string memory) {
    return 'v1';
  }

  /**
   * @dev Create a new proposal. Vote start {delay} blocks after the proposal is created and ends
   * {period} blocks after the voting starts.
   *
   * Emits a {ProposalCreated} event.
   */
  function createProposal(
    address[] memory voters,
    uint256 delay,
    uint256 period,
    string memory description,
    string[] memory options_
  ) public virtual override returns (uint256) {
    ITicket ticketToken = ITicket(tokenAddress);

    bytes32 descriptionHash = keccak256(bytes(description));
    uint256 proposalId = hashProposal(voters, delay, period, descriptionHash, options_);

    require(options_.length > 0, 'Ballot: empty options');
    require(voters.length > 0, 'Ballot: empty voters');

    ProposalData storage proposal = _proposals[proposalId];
    require(proposal.voteStart.isUnset(), 'Ballot: proposal already exists');

    _proposalIds.push(proposalId);
    _proposalDescriptions[proposalId] = description;

    uint64 snapshot = block.number.toUint64() + delay.toUint64();
    uint64 deadline = snapshot + period.toUint64();

    proposal.descriptionHash = descriptionHash;
    proposal.voteStart.setDeadline(snapshot);
    proposal.voteEnd.setDeadline(deadline);

    for (uint256 i = 0; i < voters.length; i++) {
      address voter = voters[i];

      _proposalVoters[proposalId].push(voter);
      proposal.voters[voter] = true;
      _voterProposalIds[voter].push(proposalId);

      // Check voter balanceOf
      if (ticketToken.balanceOf(voter) < 1) {
        ticketToken.safeMint(voter);
      }
    }

    for (uint256 i = 0; i < options_.length; i++) {
      bytes32 optionHash = keccak256(bytes(options_[i]));

      proposal.options.push(optionHash);
      _proposalOptionTexts[proposalId][optionHash] = options_[i];
      _proposalOptionVotes[proposalId][optionHash] = 0;
    }

    emit ProposalCreated(proposalId, _msgSender(), voters, options_, snapshot, deadline, description);

    return proposalId;
  }

  function hashProposal(
    address[] memory voters,
    uint256 delay,
    uint256 period,
    bytes32 descriptionHash,
    string[] memory options_
  ) public pure virtual override returns (uint256) {
    return uint256(keccak256(abi.encode(voters, delay, period, descriptionHash, options_)));
  }

  function castVote(uint256 proposalId, bytes32 optionHash) public virtual override {
    ProposalData storage proposal = _proposals[proposalId];
    address voter = _msgSender();

    require(!proposal.voteStart.isUnset(), 'Ballot: proposal does not exist');
    require(state(proposalId) == ProposalState.Active, 'Ballot: vote not currently active');
    require(proposal.voters[voter], 'Ballot: not a voter');

    for (uint256 i = 0; i < proposal.options.length; i++) {
      if (proposal.options[i] == optionHash) {
        _countVote(proposalId, voter, optionHash);

        emit VoteCast(_msgSender(), proposalId);

        return;
      }
    }

    revert('Ballot: invalid option');
  }

  function state(uint256 proposalId) public view virtual override returns (ProposalState) {
    ProposalData storage proposal = _proposals[proposalId];

    if (proposal.executed) {
      return ProposalState.Executed;
    }

    if (proposal.canceled) {
      return ProposalState.Canceled;
    }

    uint256 start = startsOn(proposalId);

    if (start == 0) {
      revert('Governor: unknown proposal id');
    }

    if (start >= block.number) {
      return ProposalState.Pending;
    }

    uint256 deadline = endsOn(proposalId);

    if (deadline >= block.number) {
      return ProposalState.Active;
    }

    return ProposalState.Succeeded;
  }

  function _countVote(
    uint256 proposalId,
    address voter,
    bytes32 optionHash
  ) internal virtual override {
    require(!_proposalCastedVotes[proposalId][voter], 'Ballot: vote already cast');

    _proposalOptionVotes[proposalId][optionHash] += 1;
    _proposalCastedVotes[proposalId][voter] = true;
  }

  function getOptions(uint256 proposalId) public view virtual override returns (bytes32[] memory, string[] memory) {
    uint256 length = _proposals[proposalId].options.length;
    bytes32[] memory optionHashes = new bytes32[](length);
    string[] memory optionTexts = new string[](length);

    for (uint256 i = 0; i < length; i++) {
      bytes32 optionHash = _proposals[proposalId].options[i];

      optionHashes[i] = optionHash;
      optionTexts[i] = _proposalOptionTexts[proposalId][optionHash];
    }

    return (optionHashes, optionTexts);
  }

  function proposalDescription(uint256 proposalId) public view virtual override returns (string memory) {
    return _proposalDescriptions[proposalId];
  }

  function startsOn(uint256 proposalId) public view virtual override returns (uint256) {
    return _proposals[proposalId].voteStart.getDeadline();
  }

  function endsOn(uint256 proposalId) public view virtual override returns (uint256) {
    return _proposals[proposalId].voteEnd.getDeadline();
  }

  function getProposals(address voter) public view virtual override returns (uint256[] memory) {
    return _voterProposalIds[voter];
  }

  function execute(uint256 proposalId) public payable virtual override returns (uint256) {
    ProposalState status = state(proposalId);

    require(status == ProposalState.Succeeded, 'Ballot: proposal not successful');

    _proposals[proposalId].executed = true;

    emit ProposalExecuted(proposalId);

    return proposalId;
  }

  function cancel(uint256 proposalId) public virtual override returns (uint256) {
    ProposalState status = state(proposalId);

    require(
      status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
      'Ballot: proposal not active'
    );

    _proposals[proposalId].canceled = true;

    emit ProposalCanceled(proposalId);

    return proposalId;
  }

  function _getProposalOptionVotes(uint256 proposalId) internal view virtual returns (string[] memory, uint256[] memory) {
    uint256 length = _proposals[proposalId].options.length;
    string[] memory texts = new string[](length);
    uint256[] memory votes = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      bytes32 optionHash = _proposals[proposalId].options[i];

      texts[i] = _proposalOptionTexts[proposalId][optionHash];
      votes[i] = _proposalOptionVotes[proposalId][optionHash];
    }

    return (texts, votes);
  }

  function progress(uint256 proposalId) public view virtual override returns (uint256, uint256) {
    require(state(proposalId) == ProposalState.Active, 'Ballot: vote not currently active');

    uint256 totalVoters = _proposalVoters[proposalId].length;
    uint256 totalVotes = 0;

    for (uint256 i = 0; i < totalVoters; i++) {
      if (_proposalCastedVotes[proposalId][_proposalVoters[proposalId][i]]) {
        totalVotes += 1;
      }
    }

    return (totalVoters, totalVotes);
  }

  function getResults(uint256 proposalId) public view virtual override returns (string[] memory, uint256[] memory) {
    require(state(proposalId) == ProposalState.Succeeded, 'Ballot: vote not successful');

    return _getProposalOptionVotes(proposalId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
