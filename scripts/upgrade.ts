import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const LoserFarm = await ethers.getContractFactory("LoserPredictionPool");
  const WinnerFarm = await ethers.getContractFactory("WinnerPredictionPool");
  const winnerFarm = await upgrades.upgradeProxy(process.env.WINNER_POOL_ADDRESS || "",
    WinnerFarm, {kind: "uups"}
  );
  const loserFarm = await upgrades.upgradeProxy(process.env.LOSER_POOL_ADDRESS || "",
    LoserFarm, {kind: "uups"}
  );

  console.log(`WinnerFarm implementation deployed to:${await ethers.provider.getStorageAt(
    process.env.WINNER_POOL_ADDRESS || "",
    "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
  )}`);
  
  console.log(`LoserFarm implementation deployed to:${await ethers.provider.getStorageAt(
    process.env.LOSER_POOL_ADDRESS || "",
    "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
  )}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });