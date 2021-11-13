import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const predAddress = process.env.PREDICTION_CONTRACT_ADDRESS;
  const predPerBlock = 3750000000;
  const bnbPerBlock = 10000000;

  const Wallet = await ethers.getContractFactory("PredictionWallet")
  const wallet = await Wallet.deploy(predAddress);
  const LoserFarm = await ethers.getContractFactory("LoserPredictionPoo");
  const WinnerFarm = await ethers.getContractFactory("WinnerPredictionPoo");
  const loserFarm = await upgrades.deployProxy(LoserFarm, [predAddress, bnbPerBlock, 0, wallet.address, 
    process.env.PREDICTION_CONTRACT_ADDRESS], {kind: "uups"})
  const winnerFarm = await upgrades.deployProxy(WinnerFarm, [predAddress, predPerBlock, 0, wallet.address, 
    process.env.PREDICTION_CONTRACT_ADDRESS], {kind: "uups"})
  await wallet.grantRole(ethers.utils.formatBytes32String("loserPredictionPool"), loserFarm.address);
  await wallet.grantRole(ethers.utils.formatBytes32String("winnerPredictionPool"), winnerFarm.address);

  console.log(`LoserPredictionPool deployed to:${loserFarm.address} \n
    WinnerPrediction Pool deployed to: ${winnerFarm.address}\n
    , wallet deployed to:${wallet.address}`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
