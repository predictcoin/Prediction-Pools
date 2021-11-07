import { ethers, upgrades } from "hardhat"

async function main() {
  // We get the contract to deploy
  const predPerBlock = 5000000000;
  const Pred = await ethers.getContractFactory("Predictcoin");
  const pred = await Pred.deploy();

  const Wallet = await ethers.getContractFactory("MasterPredWallet")
  const wallet = await Wallet.deploy(pred.address);
  const Farm = await ethers.getContractFactory("MasterPred");
  const farm = await upgrades.deployProxy(Farm, [pred.address, predPerBlock, 0, wallet.address], {kind: "uups"})
  await wallet.setMasterPred(farm.address);

  console.log(`Farm deployed to:${farm.address}, wallet deployed to:${wallet.address}`,
  `implementation deployed to:${await ethers.provider.getStorageAt(
    farm.address,
    "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
    )}`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
