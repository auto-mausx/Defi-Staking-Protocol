// stake: Lock tokens into smart contract 
// unstake: Unstake tokens from smart contract
// claimReward: Users get reward tokens
// What's a good reward mechanism?
// Good reward math?


// SPDX-License-Identifier: MIT

// This version of solidity automatically checks for overflow/underflow
pragma solidity ^0.8.7;

// This imports the entire contract, however to be minimalistic, we can import specific functions from the contract in order to save on gas
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {
   IERC20 public s_stakingToken;
   IERC20 public s_rewardToken;

    // someones address to how much they staked
    mapping(address => uint256) public s_balances;


    // a mapping of how much each address has been paid
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    // a mapping of how much rewards each address has
    mapping(address => uint256) public s_rewards;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account) {
        // how much reward per token?
        // last timestamp
        // 12 - 1pm, user earned x tokens
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        // this continues the rest of the code in the function this is being used in
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);


    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns(uint256) {
        uint256 currentBalance = s_balances[account];
        // how much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 tokensEarned = ((currentBalance * (currentRewardPerToken - amountPaid))/1e18) + pastRewards;
        return tokensEarned;
    }

    // based on how long it's been during this most recent snapshot
    function rewardPerToken() public view returns(uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18)/ s_totalSupply);
    }
    // do we allow any token? - not yet, only one erc20
    // chainlink stuff to convert prices between tokens for keeping track of value
    // or only specific tokens?

    // External is cheaper than public
    // The additional functions in this definition are called modifiers, 
    // and they get ran when it is noted in the modifier definition. 
    // In our case, the modifier would be ran FIRST, as notated by the "_;" char
    // in the modifier definition.
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of how much this user has staked
        // Keep track of how much token we have total
        // transfer tokens to this contract

        // Should I be using safemath for these?
        //  Will need to do research and revisit
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        // emit event
        emit Staked(msg.sender, amount);

        // IERC20 Has transferFrom function

        // The reason why we do this check here instead of before the logic is to prevent reentrancy attacks
        // Learn more here: https://solidity-by-example.org/hacks/re-entrancy
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        // require(success, "Failed"); This is more gas expensive than the below function because it returns a string.
        // Instead we are saying if this is NOT successful, return this function I declared at the top "Staking__TransferFailed()"
        if(!success) {
            // revert undos all the above logical changes and resets the transactions
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;

        // IERC20 has a transfer function to use since we have tokens already to transfer
        // You can also use the transferFrom function like so:
        // bool success = s_stakingToken.transferFrom(address(this), msg.sender, amount);
        emit WithdrewStake(msg.sender, amount);

        bool success = s_stakingToken.transfer(msg.sender, amount);

        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, reward);
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed();
        }
        // how much reward do they get?

        // The contract will emit X tokens per second
        // Then dispurse them to all token stakers

        // 100 tokens / second
        // staked: 50 staked tokens, 20 staked, 30 staked
        // rewards: 50 reward tokens, 20 reward tokens, 30 reward tokens

        // staked: 100, 50, 20, 30 (total = 200)
        // rewards: 50, 25, 10, 15

        // why not 1 to 1? - bankrupt the protocol
        

        // More people that are in this pool, the less APR is going to get less and less
        // 5 seconds, 1 person had 100 tokens staked = reward 500 tokens
        // 6 seconds, 2 persons had 100 tokens staked each:
        //      Person 1: 550
        //      Person 2: 50
        // between seconds 1 and 5: person 1 got 500 tokens
        // at second 6 on, person 1 gets 50 tokens now


        // 100 Tokens per sec
        // 1 token / staked token

        // Time = 0
        // Person A: 80 staked
        // Person B: 20 staked

        // Time = 1
        // PA: 80 staked, earned: 80, Withdrawn: 0
        // PB: 20 staked, earned: 20, Withdrawn: 0

        // Time = 2
        // PA: 80 staked, earned: 160, Withdrawn: 0
        // PB: 20 staked, earned: 40, Withdrawn: 0

        // Time = 3
        // PA: 80 staked, earned: 240, Withdrawn: 0
        // PB: 20 staked, earned: 60, Withdrawn: 0

        // New person enters!

        // Time = 3
        // PA: 80 staked, earned: 240 + 40, Withdrawn: 0
        // PB: 20 staked, earned: 60 + 10, Withdrawn: 0
        // PC: 100 staked, earned: 50, Withdrawn: 0

        // PA Withdraws everything
        // Time = 4
        // PA: 0 staked, earned: 0, Withdrawn: 280
       

    }
// Returns staked balance
    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }
}