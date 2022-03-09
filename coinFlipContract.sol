pragma solidity >=0.7.0 <0.9.0;

// set true for head
// set false for tail

/**
 * @title coinFlip
 * @dev coinFlip smart contract fow dyeus
 */
contract coinFlip {
    // struct to hold participating Players
    // which holds address of player,
    struct Player {
        address playerAdd;
        // player's guess of the coinflip
        bool commitment;
        uint256 betAmount;
        // to check whether a player
        bool engaged;
    }
    // This stores the balances of addresses
    mapping(address => uint256) public balances;
    // This map retreives the player related to the address
    mapping(address => Player) public Players;

    // owner variables
    address public gameStarter;
    // variable for keeping track of mappings length
    uint256 accountNumber;
    // below mapping is defined to help in the iteration of the Players mapping
    mapping(uint256 => address) private helperAddressMap;
    // event that emits the address and betAmount of the gambler who wins
    event Win_Add_and_betAmount(address addr, uint256 betAmount);

    constructor() {
        // set the owner
        gameStarter = msg.sender;
        // start the count of index
        accountNumber = 0;
    }

    // temporary variable to store player details
    Player public person;

    // choice is the Players betting option (true for head,false for tail)
    // amount is the money, Player is betting against.
    function placeBet(bool choice, uint256 amount) public payable {
        uint256 tempBalance;
        // adding user balance to balances mapping
        // if the Player is new, then we give 100 ethers
        if (checkPlayerExistence(msg.sender)) {
            tempBalance = msg.sender.balance;
            // if uses exists then he should not be already playing
            require(Players[msg.sender].engaged == false);
        } else {
            helperAddressMap[accountNumber] = msg.sender;
            accountNumber++;
            // adding 100 bonus points if player is new
            tempBalance = msg.sender.balance + 100 ether;
        }
        // setting the Player balance
        balances[msg.sender] = tempBalance;
        // to make sure that the amount, Player wants to bet should be less than account balance
        require(balances[msg.sender] >= amount);
        // updating the player balance after deducing the bet amount
        balances[msg.sender] = tempBalance - amount;
        // require(msg.value == betAmount);
        // START::adding player details into our Players mapping
        person.playerAdd = msg.sender;
        person.commitment = choice;
        person.betAmount = amount;
        person.engaged = true;
        // END::
        Players[msg.sender] = person;
    }

    function rewardBets() public {
        // somehow we have to convert the vrf generated random number
        // like convert it to a number then if that number is even, say it as head
        // else say it as tail

        // this function is not working correctly
        // function convert(bytes32 b) public pure returns (uint256) {
        //     return uint256(b);
        // }

        // vrf to decide heads or tail
        // bytes32 conclusion = vrf();
        // uint256 = convert(conclusion);

        // my assumption
        bool result = true; // true for head and false for tail
        // Iterating through all players for updating the account balances those who won the game.
        for (uint256 i = 0; i < accountNumber; i++) {
            address currentPlayerAddress = helperAddressMap[i];
            Player memory checkPlayer = Players[currentPlayerAddress];
            if (checkPlayer.engaged) {
                // setting the corresponding player engagement to betting false
                // to make him ready for the game from next time
                checkPlayer.engaged = false;
                if (checkPlayer.commitment == result) {
                    // player won, so we will credit 2 times the amount he used for betting to his balance
                    balances[currentPlayerAddress] += checkPlayer.betAmount * 2;
                    // emmiting the gambler address and betAmount for every win situation
                    emit Win_Add_and_betAmount(
                        currentPlayerAddress,
                        checkPlayer.betAmount
                    );
                } else {
                    // player lost and we won't update his balance
                    continue;
                }
            } else {
                // if the player is not engaged then we will skip
                continue;
            }
        }
    }

    // checks whether an address is present in the balances mapping
    function checkPlayerExistence(address user_id) public view returns (bool) {
        if (balances[user_id] > 0) {
            return true;
        } else {
            return false;
        }
    }

    // Harmony Verifiable Random Function generator function
    // more at this link: https://docs.harmony.one/home/developers/tools/harmony-vrf#how-to-access-harmony-vrf-within-smart-contract
    function vrf() public view returns (bytes32 result) {
        uint256[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }
}
