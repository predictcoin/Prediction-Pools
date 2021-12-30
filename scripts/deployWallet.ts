import { ethers } from "hardhat"

async function main() {
  const predAddress = process.env.PRED_ADDRESS;
  const Wallet = await ethers.getContractFactory("PredictionWallet")
  await Wallet.deploy(predAddress); 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });