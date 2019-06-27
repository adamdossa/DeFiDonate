const MockDepositToken = artifacts.require("./MockDepositToken.sol");
const MockCompound = artifacts.require("./MockCompound.sol");
const DeFiDonate = artifacts.require("./DeFiDonate.sol");

const BigNumber = require('bignumber.js');

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

contract('DeFiDonate', function (accounts) {

  // =========================================================================
  it("0. initialize contract", async () => {

    var mockDepositToken = await MockDepositToken.new({from: accounts[0]});
    console.log("DepositToken Address: ", mockDepositToken.address);

    var mockCompound = await MockCompound.new(mockDepositToken.address, {from: accounts[0]});
    console.log("Compound Address: ", mockCompound.address);

    var deFiDonate = await DeFiDonate.new(
        "GDAI",
        "GDAI",
        18,
        mockDepositToken.address,
        mockCompound.address,
        accounts[1],
        100,
        {from: accounts[0]});
    console.log("DeFiDonate Address: ", deFiDonate.address);

  });

});
