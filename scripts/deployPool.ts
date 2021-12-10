import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const predAddress = process.env.PRED_ADDRESS;
  const operator = process.env.OPERATOR;
  const predPerBlock = 3750000000;
  const bnbPerBlock = 50000000000;

  const wallet = await ethers.getContractAt(
    "PredictionWallet",
    process.env.WALLET_ADDRESS || "",
  );

  const LoserFarm = await ethers.getContractFactory("LoserPredictionPool");

  const loserFarm = await upgrades.deployProxy(LoserFarm, [operator, predAddress,
    process.env.BID_ADDRESS,
    bnbPerBlock, 0, ethers.utils.parseEther("500"), wallet.address, 
    process.env.PREDICTION_CONTRACT_ADDRESS], {kind: "uups"});
  
  await wallet.grantRole(ethers.utils.formatBytes32String("winnerPredictionPool"), loserFarm.address);

  console.log(`LoserPredictionPool deployed to: ${loserFarm.address}`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
