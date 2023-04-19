/* SPDX-License-Identifier: MIT */

/* Solidity version of our smart contract */
pragma solidity ^0.8.9;

/* This import statement for interacting chainlink with smart contract 
for generating random numbers */
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/* This statement is for error handling */
error notEnoughEtherSend(string errorMessage);
error winnerTransferFailed(string errorMessage);
error notOpen(string errorMessage);
error upkeepNotNeeded(string errorMessage, uint256 balance, uint256 playersLength, uint256 status);


contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {

    /* Enum type declarations */
    enum GameStatus {
        Opening,
        Calculating
    }

    /* These are all state variable for my contract */
    uint256 private immutable participateFee;
    uint256 private immutable interval;
    uint256 private lastTimeStamp;
    
    uint64 private immutable subscriptionId;

    uint32 private immutable callbackGasLimit;
    uint32 private constant numWords = 1;

    uint16 private constant requestConfirmations = 3;
    
    address payable[] private participatedPlayers;
    address private winner;

    bytes32 private immutable gasLane;
    
    GameStatus private gameStatus;
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /*  These are all events for my contract  */
    event participatedPlayersEvent(address indexed participatedPlayer);
    event reqestedRaffleWinner(uint256 indexed requestId);
    event allWinnersList(address indexed participatedWinner);


    /*  This is constructor for my contract  */
    constructor(
        address _vrfCoordinatorV2, 
        uint256 _participateFee,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        participateFee = _participateFee;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        gasLane = _gasLane;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        gameStatus = GameStatus.Opening;
        lastTimeStamp = block.timestamp;
        interval = _interval;
    }

    /* This function initialised for participate in raffle */
    function participateRaffle() public payable {
        if(msg.value < participateFee) { 
            revert notEnoughEtherSend("Not Enough Ethers Send!"); 
        }
        if(gameStatus != GameStatus.Opening){
            revert notOpen("The Game Is Not Open!");
        }

        participatedPlayers.push(payable(msg.sender));
        emit participatedPlayersEvent(msg.sender);
    }

    /* This the function that the chainlink automation nodes call 
    they look for the upkeepNeeded to return true */
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool gameOpen = (GameStatus.Opening == gameStatus);
        bool timePassed = (block.timestamp - lastTimeStamp) > interval; 
        bool hasPlayers = (participatedPlayers.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (gameOpen && timePassed && hasPlayers && hasBalance);
    }

    /* This function initialised for requesting random number in raffle 
    and this function call when checkUpKep return true */    
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert upkeepNotNeeded(
                "UpkeepNeed Is Not Return True!", 
                address(this).balance, 
                participatedPlayers.length, 
                uint256(gameStatus)
            );
        }

        gameStatus = GameStatus.Calculating;

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            gasLane,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        emit reqestedRaffleWinner(requestId);
    }

    /* This function initialised for picking random numbers in raffle */   
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % participatedPlayers.length;
        address payable recentWinner = participatedPlayers[indexOfWinner];
        winner = recentWinner;
        gameStatus = GameStatus.Opening;
        participatedPlayers = new address payable[](0);
        lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert winnerTransferFailed("That's The System Issue!");
        }
        emit allWinnersList(recentWinner);
    }

    /* This function initialised to see the participation fees */
    function getParticipateFee() public view returns(uint256) {
        return participateFee;
    }

    /* This function initialised to see the participated players */
    function getParticipatedPlayers(uint256 index) public view returns(address) {
        return participatedPlayers[index];
    }

    /*  This function initialised to get the winner */
    function getWinner() public view returns(address) {
        return winner;
    }

    /*  This function initialised to get the game status */
    function getGameStatus() public view returns(GameStatus) {
        return gameStatus;
    }

    /*  This function initialised to get num words */
    function getNumWords() public pure returns(uint256) {
        return numWords;
    }

    /*  This function initialised to get the number of player */
    function numberOfPlayers() public view returns(uint256) {
        return participatedPlayers.length;
    }

    /*  This function initialised to get the latest timestamp */
    function getLatestTimestamp()  public view returns(uint256) {
        return lastTimeStamp;
    }

    /*  This function initialised to get the confiramtion of  */
    function getRequestConfirmation() public pure returns(uint256) {
        return requestConfirmations;
    }
}