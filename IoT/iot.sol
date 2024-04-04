pragma solidity >=0.7.0 <0.9.0;

// function setLed(int8 newOn) public payable
// function readLed() public view returns (int8)

// managing the LED status value on the blockchain.
contract MessageContract {

    int8 public on;

    event MessageSet(address indexed sender, int8 newMessage);

    constructor(int8 newOn) {
        on = newOn;
    }

    // sets a new LED status value, either 0 or 1
    function setLed(int8 newOn) public payable {
        require(newOn == 0 || newOn == 1, "value must be 0 or 1");
        on = newOn;
        emit MessageSet(msg.sender, newOn);
    }

    // returns the value of the LED status, either 0 or 1
    function readLed() public view returns (int8) {
        return on;
    }
}