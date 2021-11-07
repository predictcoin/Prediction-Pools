import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const Farm = await ethers.getContractFactory("MasterPred");
  const farm = await upgrades.upgradeProxy("",
    Farm, {kind: "uups"}
  );

  console.log(`Farm implementation deployed to:${await ethers.provider.getStorageAt(
    "",
    "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
    )}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });