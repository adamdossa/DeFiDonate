const MockDepositToken = artifacts.require("./MockDepositToken.sol");
const MockCompound = artifacts.require("./MockCompound.sol");
const GovernanceToken = artifacts.require("./GovernanceToken.sol");
const DeFiDonate = artifacts.require("./DeFiDonate.sol");

const BN = require('bignumber.js');

const PREFIX = "VM Exception while processing transaction: ";
const PREFIX2 = "Returned error: VM Exception while processing transaction: ";

async function tryCatch(promise, message) {
  try {
    await promise;
    throw null;
  } catch (error) {
    assert(error, "Expected an error but did not get one");
    try {
      assert(
        error.message.startsWith(PREFIX + message),
        "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead"
      );
    } catch (err) {
      assert(
        error.message.startsWith(PREFIX2 + message),
        "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead"
      );
    }
  }
}

async function catchRevert(promise) {
  await tryCatch(promise, "revert");
}

async function advanceBlock() {
  return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        resolve(result.result);
      }
    );
  });
}

// Increases ganache time by the passed duration in seconds
async function increaseTime(duration) {
  await new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_increaseTime',
      params: [duration],
    },
    (err, result) => {
      if (err) {
        return reject(err);
      }
      resolve(result.result);
    });
  });
  await advanceBlock();
}
var mockDepositToken;
var mockCompound;
var deFiDonate;
var govToken;
var ONE_WEEK = 60 * 60 * 24 * 7;
var ONE_MONTH = 60 * 60 * 24 * 28;
let WEI = 1000000000000000000;

contract('DeFiDonate', function (accounts) {

  // =========================================================================
  it("0. initialize contract", async () => {

    mockDepositToken = await MockDepositToken.new({from: accounts[0]});
    console.log("DepositToken Address: ", mockDepositToken.address);

    mockCompound = await MockCompound.new(mockDepositToken.address, {from: accounts[0]});
    console.log("Compound Address: ", mockCompound.address);

    deFiDonate = await DeFiDonate.new(
        "CHARITY DAI",
        "CHARITY_DAI",
        18,
        mockDepositToken.address,
        mockCompound.address,
        accounts[1],
        BN(ONE_MONTH),
        BN(ONE_WEEK),
        {from: accounts[0]});
    console.log("DeFiDonate Address: ", deFiDonate.address);

    var govAddress = await deFiDonate.governanceToken();
    console.log("GovToken Address: " + govAddress);
    govToken = await GovernanceToken.at(govAddress);

  });

  it("1. deposits some funds", async () => {
    console.log(BN(1000).times(10**18));
    console.log(BN(1000).times(10**18).toNumber());
    // console.log(web3.utils.toWei(1000));
    // console.log(web3.utils.toWei(1000).toNumber());
    // console.log(web3.utils.toWei(BN(1000)));
    // console.log(web3.utils.toWei(BN(1000)).toNumber());
    let amt = BN(String(1000)).times(String(WEI));
    console.log("At Block: " + await govToken.blockNumber());
    await mockDepositToken.mint(accounts[0], 1000, {from: accounts[0]});
    console.log("At Block: " + await govToken.blockNumber());
    await mockDepositToken.mint(accounts[1], 1000, {from: accounts[0]});
    console.log("At Block: " + await govToken.blockNumber());
    await mockDepositToken.approve(deFiDonate.address, 1000, {from: accounts[0]});
    console.log("At Block: " + await govToken.blockNumber());
    await deFiDonate.wrap(1000, {from: accounts[0]});
  });

  it("2. check governance balances after 4 days / blocks", async () => {
    await advanceBlock();
    await advanceBlock();
    await advanceBlock();
    await advanceBlock();
    await increaseTime(60 * 60 * 24 * 4);
    console.log("At Block: " + await govToken.blockNumber());
    console.log((await govToken.balanceOf(accounts[0])).toNumber());
    console.log((await govToken.balanceOf(accounts[1])).toNumber());
  });

  it("3. check governance balances after 2 weeks", async () => {
    console.log("At Block: " + await govToken.blockNumber());
    for (var i = 0; i < 10; i++) {
        await advanceBlock();
    }
    await increaseTime(60 * 60 * 24 * 10);
    console.log((await govToken.balanceOf(accounts[0])).toNumber());
    console.log((await govToken.balanceOf(accounts[1])).toNumber());
  });

  it("4. do some voting", async () => {
    // console.log((await deFiDonate.nextEpoch()).toNumber());
    // console.log((await deFiDonate.coolOffLength()).toNumber());
    // console.log((await govToken.blockTime()).toNumber());
    let voteBalance = (await govToken.balanceOf(accounts[0])).toNumber();
    console.log("Voting Balance: " + voteBalance);
    await deFiDonate.vote(accounts[3], 100, "Account3", {from: accounts[0]});
    console.log("Winning Charity: " + await deFiDonate.largestCharity());
    console.log("Winning Votes: " + await deFiDonate.largestVote());
    voteBalance = (await govToken.balanceOf(accounts[1])).toNumber();
    console.log("Remaining Balance: " + voteBalance);
  });

  it("4. transfer govTokens and do some more voting", async () => {
    // console.log((await deFiDonate.nextEpoch()).toNumber());
    // console.log((await deFiDonate.coolOffLength()).toNumber());
    // console.log((await govToken.blockTime()).toNumber());
    await govToken.transfer(accounts[5], 200, {from: accounts[0]});
    let voteBalance = (await govToken.balanceOf(accounts[5])).toNumber();
    console.log("Voting Balance: " + voteBalance);
    await deFiDonate.vote(accounts[3], 200, "Account3", {from: accounts[5]});
    console.log("Winning Charity: " + await deFiDonate.largestCharity());
    console.log("Winning Votes: " + await deFiDonate.largestVote());
    voteBalance = (await govToken.balanceOf(accounts[5])).toNumber();
    console.log("Remaining Balance: " + voteBalance);
  });

  it("4. do even more voting", async () => {
    // console.log((await deFiDonate.nextEpoch()).toNumber());
    // console.log((await deFiDonate.coolOffLength()).toNumber());
    // console.log((await govToken.blockTime()).toNumber());
    let voteBalance = (await govToken.balanceOf(accounts[0])).toNumber();
    console.log("Voting Balance: " + voteBalance);
    await deFiDonate.vote(accounts[4], 1000, "Account3", {from: accounts[0]});
    console.log("Winning Charity: " + await deFiDonate.largestCharity());
    console.log("Winning Votes: " + await deFiDonate.largestVote());
    voteBalance = (await govToken.balanceOf(accounts[1])).toNumber();
    console.log("Remaining Balance: " + voteBalance);
  });

  it("4. pay out to charity", async () => {
    console.log("Cool Off Length: " + (await deFiDonate.coolOffLength()).toNumber());
    console.log("Next Epoch: " + (await deFiDonate.nextEpoch()).toNumber());
    console.log("Block Time: " + (await govToken.blockTime()).toNumber());
    await increaseTime(60 * 60 * 24 * 14);
    console.log("Next Epoch: " + (await deFiDonate.nextEpoch()).toNumber());
    console.log("Block Time: " + (await govToken.blockTime()).toNumber());

    let charity = await deFiDonate.charity();
    console.log("Old Charity Balance: " + (await mockDepositToken.balanceOf(charity)));
    await deFiDonate.epochDonate();
    console.log("New Charity Balance: " + (await mockDepositToken.balanceOf(charity)));

    console.log("Next Epoch: " + (await deFiDonate.nextEpoch()).toNumber());
    console.log("Block Time: " + (await govToken.blockTime()).toNumber());

    console.log("Paid Charity: " + charity);
    console.log("New Charity: " + await deFiDonate.charity());
    console.log("Winning Charity: " + await deFiDonate.largestCharity());
    console.log("Winning Votes: " + await deFiDonate.largestVote());
  });

});
