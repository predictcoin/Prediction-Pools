const hre = require("hardhat");
const { ethers } = hre;

const CONTRACT_ADDRESS = "0x13DEa0f9F9056bD2c4162439856b12Df6c4569e6";
const CONSTRUCTOR_ARGUMENTS: any[] = []

async function main () {

  try {
    await hre.run("verify:verify", {
      address: CONTRACT_ADDRESS,
      constructorArguments: CONSTRUCTOR_ARGUMENTS,
    });
  } catch (error) {
    console.log(`Failed to verify: Bid Token @${CONTRACT_ADDRESS}`);
    console.log(error);
  }

};
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
