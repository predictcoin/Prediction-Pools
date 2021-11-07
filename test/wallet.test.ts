import { expect } from "chai";
import { ethers } from "hardhat"
import { Signer, Contract, BigNumber as _BigNumber, BigNumber, ContractFactory } from "ethers";

let Wallet: ContractFactory, wallet: Contract, PrederB: Signer, pred: Contract, Pred: ContractFactory;

describe("MasterPred Wallet Tests", () => {
  beforeEach( async () => {
    Pred = await ethers.getContractFactory("Predictcoin")
    pred = await Pred.deploy()
    Wallet = await ethers.getContractFactory("MasterPredWallet")
    wallet = await Wallet.deploy(pred.address);
    pred.transfer(wallet.address, 1000000);

    const signers = await ethers.getSigners();
    [, PrederB] = signers;
  })

  it("should allow Owner send Pred", async () => {
    await expect(async () => wallet.safePredTransfer(await PrederB.getAddress(), 10000))
      .to.changeTokenBalances(
        pred, [wallet, PrederB], [-10000, 10000]
    )
  })

  it("should allow onlyOwner send Pred", async () => {
    await expect(wallet.safePredTransfer(
      await PrederB.getAddress(), 10000, {from: PrederB}
      )
    ).to.be.reverted;
  })

  it("should allow Owner set MasterPred", async () => {
    await wallet.setMasterPred(await PrederB.getAddress())
    const master = await wallet.MasterPred()
    expect(master).to.equal(await PrederB.getAddress())
  })

  it("should allow only Owner set MasterPred", async () => {
    await expect(wallet.setMasterPred(
      await PrederB.getAddress(), {from: PrederB}
    )).to.be.reverted
  })
})