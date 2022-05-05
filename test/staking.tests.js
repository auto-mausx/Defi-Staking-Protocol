const {ethers, deployments} = require("hardhat");
const {moveBlocks} = require("../utils/move-blocks");
const {moveTime} = require("../utils/move-time");

const SECONDS_IN_A_DAY = 86400;
const SECONDS_IN_A_YEAR = 31449600;

describe("Staking Test", async function() {
    let staking, rewardToken, deployer, stakeAmount

    beforeEach(async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0];

        await deployments.fixture(["all"]);
        staking = await ethers.getContract("staking");
        rewardToken = await ethers.getContract("RewardToken");
        stakeAmount = ethers.utils.parseEther("100000")
    })

    it("Allows users to stake and claim rewards", async () => {
        await rewardToken.approve(staking.address, stakeAmount);
        await staking.stake(stakeAmount);
        const startingEarned = await staking.earned(deployer.address);
        console.log(`Starting Earned ${startingEarned}`);

        await moveTime(SECONDS_IN_A_DAY);
        await moveBlocks(1);

        const endingDayEarned = await staking.earned(deployer.address);
        console.log(`Ending Earned Day ${endingDayEarned}`);

        await moveTime(SECONDS_IN_A_YEAR);
        await moveBlocks(1);

        const endingYearEarned = await staking.earned(deployer.address);
        console.log(`Ending Earned Year ${endingYearEarned}`);
    })
})