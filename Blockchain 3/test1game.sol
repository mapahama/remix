pragma solidity ^0.8.25;

// TODO: if number of registered players is <3, dont start the game and return the money to the players

contract Game {
    // address of the contract owner receives the  fees from the game praticipants
    address owner; // 
    // set a limited period of time, how long should the game run
    uint  startTime;
    uint  endTime;

    // contains addresses of the game participants
    address[] allAddresses;

    // called only once, when the contract is deployed on the blockchain
    // the owner is the deployer of the contract (message sender)
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp; 
    }


    // add reusable checks to functions (who can call it), which can help in reducing redundancy and making the code cleaner
    modifier onlyOwnerHasAccess() {
        require(msg.sender == owner, "Only the smart contract owner can call this function!");
        _; // This is where the modified function's code will be inserted, if require statement gets fulfilled
    }

    // test function that shows smart contract owners address
    function testShowOwnerAddress() public view returns(address){
        return owner;
    }

    // the function appears in the control panel as a button, parameters must be entered
    // gamePeriod param - low long the game should continue
    // the function is public - acessable outside of this smart contract
    // only the owner of the smart contract has access to start the game (definded in "require" function)
    // onlyOwnerHasAccess - we are calling the modifier function, before executing the "startGame" code body
    function startGame(uint gamePeriod) public onlyOwnerHasAccess {

        startTime = block.timestamp;      // gives the current time in seconds
        endTime = startTime + gamePeriod; // counter - defines how much time the players have to participate in the
                                          // game, before it ends
                                          // should be programmed so, that the game restarts automatically every few min
    }


    // the function appears in the control panel as a button, NO parameters must be entered
    // the function is public - acessable outside of this smart contract
    // payable means that transactions can be sent via this function and published on the blockchain (write)
    function payFeeToEnterGame() public payable {
        // if current time of the !PLAYER! calling this func
        // is < than the manually defined endTime,
        // a player still has chance to participate 
        // Should be programmed so, that the game restarts
        // automatically every few min
        require(block.timestamp < endTime, "The game has already ended");  

        // "msg" in this case is the transaction of the
        // !PLAYER! msg.value should de equal to 1 ether
        // so this is the game fee, which the player pays
        require(msg.value == 10000000 gwei, "The ether amount supplied is wrong.");   // TODO try with >= 1 ether

        // push the address of the person calling this function in the array with addresses
        // so "msg.sender" gives us the address of the current player, calling this function  
        allAddresses.push(msg.sender);

        // TODO: contract owner should not be able to enter the game

    }


    // the function appears in the control panel as a button, NO parameters must be entered
    // "public" - acessable outside of this smart contract
    // "view" - can only read information from the blockchain
    // the function gives information about the current ether balance of this smart contract
    function contractBalance() public view returns(uint) {
        return address(this).balance;  // returns the ether balance of this smart contract
    }

    // the function appears in the control panel as a button, NO parameters must be entered
    // "public" - acessable outside of this smart contract
    // payable means that transactions can be sent via this function and published on the blockchain (write)
    // we send the prize of the game to the winner player
    // onlyOwnerHasAccess - we are calling the modifier function, before executing the "endGame" code body
    function endGame() public payable onlyOwnerHasAccess returns (bool) {
        
        require(block.timestamp > endTime, "The game is still going on...");  // game can not be ended, if its still going on

        
        // select the address of the winner at RANDOM from the array with player addresses
        // block.timestamp, block.chainid are different on every function call, so its suitable for random numbers
        // keccak256 is a hash algorithm
        // we use % allAdresses in order to keep the number in the range of the array length and not higher
        uint arrIndexOfWinner = uint(keccak256(abi.encodePacked(block.timestamp, block.chainid, msg.sender))) % allAddresses.length;

        // TODO: use Chainlink VRF --> Oracle
        // to generate Random Numbers! Its much safer than the function implemented here in the smart contract
        // So the random number will be generated not in solidity, but off chain

        address winner = allAddresses[arrIndexOfWinner];

        uint feeForOwner = address(this).balance * 20 / 100;  // calculate 20% of smart contract balance for the game manager
        (bool sentToOwner,) = owner.call{value: feeForOwner}("");

        require(sentToOwner, "Failed to send ether to the owner");


        // bool variable, contains TRUE or FALSE (if the prize was sent to the winner successfully)
        // WHY a comma "," is used after bool sent?
        // winner.call(...) returns many values, with the comma "," we make it clear
        // that we dont want to receive all the values from "call()" function, but only the first value - tx sent successfully - TRUE or FALSE
        (bool sentToWinner,) = winner.call{value: address(this).balance}(""); // send the deposited entry fee amounts from the players
                                                                      // to the winner address
                                                                      // address(this).balance  gives the deposited from players
                                                                      // balance in this smart contract
                                                                      // tax to the manager is send in function "payFeeToEnterGame"

                                                                      // so after sending the prize to the winner, this smart contract
                                                                      // should have EMPTY balance
        require(sentToWinner, "Failed to send ether to the winner");


        return sentToWinner;
    }
}