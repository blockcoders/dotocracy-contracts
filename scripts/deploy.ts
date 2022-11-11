import { run, ethers, network } from 'hardhat';

async function main() {
  run('compile');
  
  const Ticket = await ethers.getContractFactory('Ticket');
  const ticket = await Ticket.deploy('DotocracyNFTVotes', 'DOTONFTV');

  console.log('Ticket deployed to:', ticket.address);
  
  await ticket.deployed();
  
  if (ticket.newlyDeployed) {
    await run('verify:verify', {
      address: ticket.address,
      constructorArguments: ['DotocracyNFTVotes', 'DOTONFTV'],
    });
  }  
  
  const Ballot = await ethers.getContractFactory('Ballot');
  const ballot = await Ballot.deploy(ticket.address, 'DotocracyBallot');
  
  console.log('Ballot deployed to:', ballot.address);
  
  await ballot.deployed();
  
  await run('verify:verify', {
    address: ballot.address,
    constructorArguments: [ticket.address, 'DotocracyBallot'],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
