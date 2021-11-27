// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IPrediction.sol";
import "./utils/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./PredictionWallet.sol";

//import "hardhat/console.sol";

//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract WinnerPredictionPool is Initializable, PausableUpgradeable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PREDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPredPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPredPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // share of predPerBlock
        uint256 lastRewardBlock; // Last block number that PREDs distribution occurs.
        uint256 accPredPerShare; // Accumulated PREDs per share, times 1e12. See below.
        uint256 epoch; // epoch of round winners that can stake
        uint256 amount;
    }

    // The PRED TOKEN!
    IBEP20 public pred;
    // Prediction contract
    IPrediction public prediction;
    // PRED tokens distributed per block.
    uint256 public predPerBlock;
    // Bonus muliplier for early preders.
    uint256 public BONUS_MULTIPLIER;
    //contract holding PRED tokens
    PredictionWallet public wallet;
    uint256 public maxPredDeposit;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes PRED.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Allocation point for the running pool
    uint256 public allocPoint;
    // The block number when PRED mining starts.
    uint256 public startBlock;
    // Amount of Predictioin wallet balance already allocated to pools
    uint256 public totalRewardDebt;

    address public operatorAddress;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event NewOperatorAddress(address operator);

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    function initialize(
        address _operator,
        IBEP20 _pred,
        uint256 _predPerBlock,
        uint256 _startBlock,
        uint256 _maxPredDeposit,
        PredictionWallet _wallet,
        IPrediction _prediction
    ) external initializer {
        __Ownable_init();
        operatorAddress = _operator;
        pred = _pred;
        predPerBlock = _predPerBlock;
        startBlock = _startBlock;
        wallet = _wallet;
        prediction = _prediction;
        maxPredDeposit = _maxPredDeposit;

        BONUS_MULTIPLIER = 1000000;
        allocPoint = 200;
    }
    
    // Authourizes upgrade to be done by the proxy. Theis contract uses a UUPS upgrade model
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function add(uint _epoch) external {
        // get Round for pid
        (,,,, bool oraclesCalled1,,,,,,) = prediction.getRound(_epoch);
        require(oraclesCalled1, "Round was not successful or not complete");
        
        uint256 currentEpoch = prediction.currentEpoch();
        if(currentEpoch != _epoch){
            (,,,, bool oraclesCalled2,,,,,,) = prediction.getRound(currentEpoch);
            require(!oraclesCalled2, "Current Round is already complete");
        }
        
        
        if(poolInfo.length > 0){
            uint index = poolInfo.length-1;
            require(poolInfo[index].epoch < _epoch, "New epoch cannot be less or equal to past epoch");
            updatePool(index);
            poolInfo[poolInfo.length-1].allocPoint = 0;
        }
        _add(allocPoint, _epoch);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function _add(
        uint256 _allocPoint,
        uint256 epoch
    ) internal onlyOperator {
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                epoch: epoch,
                lastRewardBlock: lastRewardBlock,
                accPredPerShare: 0,
                amount: 0
            })
        );
    }

    // Update the given pool's PRED allocation point. Can only be called by the owner.
    function setPoolAllocPoint(
        uint256 _allocPoint
    ) public onlyOwner {
        uint poolId = poolInfo.length-1;
        updatePool(poolId);
        poolInfo[poolId].allocPoint = _allocPoint;
    }

    // Update the allocPoint.Can only be called by the Owner.
    function setAllocPoint(
        uint256 _allocPoint
    ) public onlyOwner {
        allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PREDs on frontend.
    function pendingPred(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPredPerShare = pool.accPredPerShare;
        uint256 predSupply = pred.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && predSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 predReward = multiplier
            .mul(predPerBlock);

            uint256 predBal = pred.balanceOf(address(wallet)).sub(
                totalRewardDebt
            );
            if (predReward >= predBal) {
                predReward = predBal;
            }
            accPredPerShare = accPredPerShare.add(
                predReward.mul(1e30).div(predSupply)
            );
        }
        return user.amount.mul(accPredPerShare).div(1e30).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 predSupply = pred.balanceOf(address(this));
        if (predSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 predReward = multiplier
            .mul(predPerBlock);
        uint256 predBal = pred.balanceOf(address(wallet)).sub(totalRewardDebt);
        if (predReward >= predBal) {
            predReward = predBal;
        }

        pool.accPredPerShare = pool.accPredPerShare.add(
            predReward.mul(1e30).div(predSupply)
        );
        totalRewardDebt = totalRewardDebt.add(predReward);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to PredictionWallet for PRED allocation.
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        require(prediction.wonRound(msg.sender, pool.epoch), "Did not win this Prediction round");
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accPredPerShare)
            .div(1e30)
            .sub(user.rewardDebt);
            if (pending > 0) {
                safePredTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balBefore = pred.balanceOf(address(this));
            pred.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(
                pred.balanceOf(address(this)).sub(balBefore)
            );
            pool.amount = pool.amount.add(
                pred.balanceOf(address(this)).sub(balBefore)
            );
            require(user.amount <= maxPredDeposit, "Max PRED Deposit Reached");
        }
        user.rewardDebt = user.amount.mul(pool.accPredPerShare).div(1e30);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from PredictionWallet.
    function withdraw(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPredPerShare).div(1e30).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safePredTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.amount = pool.amount.sub(_amount);
            pred.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPredPerShare).div(1e30);
        poolInfo[_pid] = pool;
        emit Withdraw(msg.sender, _pid, _amount);
    }
    

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public whenPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 pending = amount
            .mul(pool.accPredPerShare)
            .div(1e30)
            .sub(user.rewardDebt);
        if (pending <= totalRewardDebt){
            totalRewardDebt = totalRewardDebt.sub(pending);
        }
        pred.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    
    // Safe pred transfer function, just in case if rounding error causes pool to not have enough PREDs.
    function safePredTransfer(address _to, uint256 _amount) internal {
        totalRewardDebt = totalRewardDebt.sub(
            wallet.safePredTransfer(_to, _amount)
        );
    }
    
    function setMaxPredDeposit(uint _maxPredDeposit) external {
        maxPredDeposit = _maxPredDeposit;
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }
    
    function getPoolLength() public view returns(uint256){
        return poolInfo.length;
    }

    function wonRound(address preder, uint round) external view returns(bool){
        return prediction.wonRound(preder, round);
    }

    function lostRound(address preder, uint round) external view returns(bool){
        return prediction.lostRound(preder, round);
    }

    //pause deposits and withdrawals and allow only emergency withdrawals(forfeit funds)
    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}
