// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/governance/Governor.sol';
import '@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotes.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol';

contract Ballot is Governor, GovernorCompatibilityBravo, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
  uint256 private _delay;
  uint256 private _period;

  constructor(
    IVotes _token,
    TimelockController _timelock,
    uint256 quorum_,
    uint256 delay,
    uint256 period
  ) Governor('Ballot') GovernorVotes(_token) GovernorVotesQuorumFraction(quorum_) GovernorTimelockControl(_timelock) {
    _delay = delay;
    _period = period;
  }

  function votingDelay() public view override returns (uint256) {
    return _delay;
  }

  function votingPeriod() public view override returns (uint256) {
    return _period;
  }

  function proposalThreshold() public pure override returns (uint256) {
    return 0;
  }

  // The functions below are overrides required by Solidity.

  function quorum(uint256 blockNumber) public view override(IGovernor, GovernorVotesQuorumFraction) returns (uint256) {
    return super.quorum(blockNumber);
  }

  function getVotes(address account, uint256 blockNumber) public view override(IGovernor, Governor) returns (uint256) {
    return super.getVotes(account, blockNumber);
  }

  function state(uint256 proposalId) public view override(Governor, IGovernor, GovernorTimelockControl) returns (ProposalState) {
    return super.state(proposalId);
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
    return super.propose(targets, values, calldatas, description);
  }

  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId) public view override(Governor, IERC165, GovernorTimelockControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
