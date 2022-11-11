import chai, { expect } from 'chai';
import { takeSnapshot, SnapshotRestorer } from '@nomicfoundation/hardhat-network-helpers';
import { MockContract, MockContractFactory, smock } from '@defi-wonderland/smock';
import { Ticket, Ticket__factory } from '@typechained';

chai.use(smock.matchers);

describe('Ticket', () => {
  const deployer = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  const name = 'DotocracyNFTVotes'
  const symbol = 'DOTONFTV'
  const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
  let ticket: MockContract<Ticket>;
  let ticketFactory: MockContractFactory<Ticket__factory>;
  let snapshot: SnapshotRestorer;

  before(async () => {
    ticketFactory = await smock.mock<Ticket__factory>('Ticket');
    ticket = await ticketFactory.deploy(name, symbol);
    snapshot = await takeSnapshot();
  });

  beforeEach(async () => {
    await snapshot.restore();
  });

  it('token has correct name', async function () {
    expect(await ticket.name()).to.equal(name);
  });
  
  it('token has correct symbol', async function () {
    expect(await ticket.symbol()).to.equal(symbol);
  });
  
  it('deployer has the default admin role', async function () {
    expect(await ticket.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(deployer);
  });
});
