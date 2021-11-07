// SPDX-License-Identifier: Unlicensed
//Just for tests
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken1 is ERC20("BUSDPRED","BUSDPRED"){
    constructor(){
        _mint(msg.sender, 10000000);
    }
}

contract LPToken2 is ERC20("BNBPRED","BNBPRED"){
    constructor(){
        _mint(msg.sender, 10000000);
    }
}