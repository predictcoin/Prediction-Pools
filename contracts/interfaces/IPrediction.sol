pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


interface IPrediction{
    enum Position {
        Bull,
        Bear
    }

    struct Round {
        uint256 epoch;
        uint256 lockedTimestamp;
        uint256 closeTimestamp;
        uint256 totalAmount;
        bool oraclesCalled;
        mapping(address => uint256) lockedOracleIds;
        mapping(address => uint256) closeOracleIds;
        mapping(address => uint256) bets;
        mapping(address => int) lockedPrices;
        mapping(address => int) closePrices;
    }

    struct BetInfo {
        Position position;
        address token;
        uint256 amount;
        bool claimed; // default false
    }
    
    
    function addTokens(address[] memory _tokens, address[] memory _oracles) external;
    
    function removeTokens(uint[] memory _ids) external;
    
    function getTokens() external view returns(address[] memory);

    /**
     * @notice Bet bear position
     * @param epoch: epoch
     */
    function predictBear(uint256 epoch, address token) external;

    /**
     * @notice Bet bull position
     * @param epoch: epoch
     */
    function predictBull(uint256 epoch, address token) external;
    

    /**
     * @notice Claim refund for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(uint256[] calldata epochs) external;
    
    
    function startRound() external;
    
    function endRound() external;
    
    function getRound(uint _round) external view 
        returns(
            uint256 epoch,
            uint256 lockedTimestamp,
            uint256 closeTimestamp,
            uint256 totalAmount,
            bool oraclesCalled,
            address[] memory _tokens,
            int256[] memory lockedPrices,
            int256[] memory closePrices,
            uint256[] memory lockedOracleIds,
            uint256[] memory closeOracleIds,
            uint256[] memory bets
        );

    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfo[] memory,
            uint256
        );
        
    function currentEpoch() external returns(uint256);

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view;


    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(uint256 epoch, address user) external view returns (bool);
    
    /**
     * @notice Checks if an address won the last round
    */
    
    
    function wonRound(address preder, uint round) external view returns(bool); 
    
    function lostRound(address preder, uint round) external view returns(bool);
    
    function ledger(uint256 round, address preder) external view returns(BetInfo memory);
    
}