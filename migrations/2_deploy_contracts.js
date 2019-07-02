const DeFiDonate = artifacts.require("./DeFiDonate.sol");
const MockDepositToken = artifacts.require("./MockDepositToken.sol");
const MockCompound = artifacts.require("./MockCompound.sol");
const GovernanceToken = artifacts.require("./GovernanceToken.sol");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(MockDepositToken, {from: accounts[0]});
  await deployer.deploy(MockCompound, MockDepositToken.address, {from: accounts[0]});
  //await deployer.deploy(DeFiDonate, "Charitable DAI", "CHARITY_DAI", 18, "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea", "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14", "0x85523D0f76B3A6C3c05b2CfBb0558B45541f100B", 60 * 60 * 24 * 30, 60 * 60 * 24 * 7, {from: accounts[0]});
  await deployer.deploy(DeFiDonate, "Charitable DAI", "CHARITY_DAI", 18, MockDepositToken.address, MockCompound.address, accounts[0], 60 * 60 * 24 * 30, 60 * 60 * 24 * 7, {from: accounts[0]});
  let mockDepositToken = await MockDepositToken.at(MockDepositToken.address);
  await mockDepositToken.mint(accounts[0], 1000000, {from: accounts[0]});
  await mockDepositToken.approve(DeFiDonate.address, 10000000, {from: accounts[0]});
  let deFiDonate = await DeFiDonate.at(DeFiDonate.address);
  await deFiDonate.wrap(1000, {from: accounts[0]});
  await GovernanceToken.at(await deFiDonate.governanceToken());
  console.log("GovToken: " + await deFiDonate.governanceToken())
};
