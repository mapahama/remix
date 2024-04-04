pragma solidity ^0.8.25;

contract TestEvent {

    event testt(uint num);

    function testEv() public {
        emit testt(21);
    }
}