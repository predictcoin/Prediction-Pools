import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const predAddress = process.env.PRED_ADDRESS;
  const operator = process.env.OPERATOR;
  const predPerBlock = 3750000000;

  const wallet = await ethers.getContractAt(
    "PredictionWallet",
    process.env.WALLET_ADDRESS || "",
  );

  const WinnerFarm = await ethers.getContractFactory("WinnerPredictionPool");
  const winnerFarm = await upgrades.deployProxy(WinnerFarm, [operator, predAddress, predPerBlock, 0, ethers.utils.parseEther("100"), wallet.address, 
    process.env.PREDICTION_CONTRACT_ADDRESS], {kind: "uups"})
  await wallet.grantRole(ethers.utils.formatBytes32String("winnerPredictionPool"), winnerFarm.address);

  console.log(`
    WinnerPrediction Pool deployed to: ${winnerFarm.address}
    Wallet deployed to: ${wallet.address}`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
