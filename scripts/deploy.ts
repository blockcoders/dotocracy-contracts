import { run, ethers, network } from 'hardhat';

async function main() {
  run('compile');
  
  const owner = '0x1cEE71f0821fB7d3CCBaCaA221AC7e354bC7E439';
  const Ticket = await ethers.getContractFactory('Ticket');
  const ticket = await Ticket.deploy();

  console.log('Ticket deployed to:', ticket.address);
  
  await ticket.deployed();
  
  await run('verify:verify', {
    address: ticket.address,
    constructorArguments: [],
  });
  
  const TimelockController = await ethers.getContractFactory('TimelockController');
  const timelockController = await TimelockController.deploy(30, [owner], [owner], owner);
  
  console.log('TimelockController deployed to:', timelockController.address);
  
  await timelockController.deployed();
  
  await run('verify:verify', {
    address: timelockController.address,
    constructorArguments: [30, [owner], [owner], owner],
  });
  
  const Ballot = await ethers.getContractFactory('Ballot');
  const ballot = await Ballot.deploy(ticket.address, timelockController.address, 6, 6575, 46027);
  
  console.log('Ballot deployed to:', ballot.address);
  
  await ballot.deployed();
  
  await run('verify:verify', {
    address: ballot.address,
    constructorArguments: [ticket.address, timelockController.address, 6, 6575, 46027],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
