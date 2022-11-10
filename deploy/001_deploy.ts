import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { shouldVerifyContract } from '../utils/deploy';

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();

  const deploy = await hre.deployments.deploy('Ticket', {
    contract: 'contracts/Ticket.sol:Ticket',
    from: deployer,
    args: [],
    log: true,
  });
  
  if (await shouldVerifyContract(deploy)) {
    await hre.run('verify:verify', {
      address: deploy.address,
      constructorArguments: [],
    });
  }
};
deployFunction.dependencies = [];
deployFunction.tags = ['Ticket'];
export default deployFunction;
