// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.2;

import "./interfaces/IBEP20.sol";
import './utils/SafeBEP20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract MasterPredWallet is Ownable {
    using SafeBEP20 for IBEP20;
    // The PRED TOKEN!
    IBEP20 public pred;
    address public MasterPred;

    constructor(
        IBEP20 _pred
    ) {
        pred = _pred;
    }

    function setMasterPred(address _MasterPred) onlyOwner external{
        MasterPred = _MasterPred;
    }

    // Safe pred transfer function, just in case if rounding error causes pool to not have enough PREDs.
    function safePredTransfer(address _to, uint256 _amount) public returns(uint) {
        require(msg.sender == MasterPred || msg.sender == owner(), "Wallet: Only MasterPred and Owner can transfer");
        uint256 predBal = pred.balanceOf(address(this));
        if (_amount > predBal) {
            pred.safeTransfer(_to, predBal);
            return predBal;
        } else {
            pred.safeTransfer(_to, _amount);
            return _amount;
        }
    }
}