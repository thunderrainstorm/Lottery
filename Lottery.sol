// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TieredLottery {
    // Entities
    address public manager;
    address payable[] public players;
    address payable[] public winners; // Stores all winners
    address payable public jackpotWinner;
    uint public jackpotBalance;
    uint public round;
    uint public constant JACKPOT_ROUND_INTERVAL = 5; // Jackpot drawn every 5 rounds
    uint public constant JACKPOT_PERCENTAGE = 10; // 10% of each participation goes to jackpot

    // Events
    event WinnersSelected(address firstWinner, address secondWinner, address thirdWinner);
    event JackpotWinnerSelected(address jackpotWinner, uint amount);

    constructor() {
        manager = msg.sender;
        round = 1;
    }

    function participate() public payable {
        require(msg.value == 1 ether, "Please pay 1 ether only");
        
        // Deduct 10% for jackpot
        uint jackpotContribution = (msg.value * JACKPOT_PERCENTAGE) / 100;
        jackpotBalance += jackpotContribution;

        // Add the remaining 90% to the prize pool
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(manager == msg.sender, "You are not the manager");
        return address(this).balance;
    }

    function getJackpotBalance() public view returns (uint) {
        return jackpotBalance;
    }

    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinners() public {
        require(manager == msg.sender, "You are not the manager");
        require(players.length >= 3, "Players are less than 3");

        // Select three winners
        uint r = random();
        uint index1 = r % players.length;
        uint index2 = (r + 1) % players.length;
        uint index3 = (r + 2) % players.length;

        address payable firstWinner = players[index1];
        address payable secondWinner = players[index2];
        address payable thirdWinner = players[index3];

        // Distribute prizes
        uint totalPool = getBalance() - jackpotBalance;
        firstWinner.transfer((totalPool * 50) / 100); // 50% to first winner
        secondWinner.transfer((totalPool * 30) / 100); // 30% to second winner
        thirdWinner.transfer((totalPool * 20) / 100); // 20% to third winner

        // Store winners
        winners.push(firstWinner);
        winners.push(secondWinner);
        winners.push(thirdWinner);

        // Emit event for winners
        emit WinnersSelected(firstWinner, secondWinner, thirdWinner);

        // Check if it's time to draw the jackpot
        if (round % JACKPOT_ROUND_INTERVAL == 0) {
            drawJackpot();
        }

        // Reset players for the next round
        players = new address payable[](0);

        // Increment the round counter
        round++;
    }

    function drawJackpot() internal {
        require(jackpotBalance > 0, "No jackpot to draw");
        require(players.length > 0, "No players to select as jackpot winner");

        // Select a random player from all participants as the jackpot winner
        uint r = random();
        uint index = r % players.length;
        jackpotWinner = players[index];

        // Transfer the jackpot
        jackpotWinner.transfer(jackpotBalance);

        // Emit event for jackpot winner
        emit JackpotWinnerSelected(jackpotWinner, jackpotBalance);

        // Reset jackpot
        jackpotBalance = 0;
    }

    function getWinners() public view returns (address payable[] memory) {
        return winners;
    }

    function getRound() public view returns (uint) {
        return round;
    }

    function getPlayerCount() public view returns (uint) {
        return players.length;
    }
}
