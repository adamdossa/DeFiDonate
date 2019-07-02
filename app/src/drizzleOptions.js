import DeFiDonate from "./contracts/DeFiDonate.json";
import MockDepositToken from "./contracts/MockDepositToken.json";
import GovernanceToken from "./contracts/GovernanceToken.json";

const options = {
  web3: {
    block: false,
    fallback: {
      type: "ws",
      url: "ws://127.0.0.1:9545",
    },
  },
  syncAlways: true,
  contracts: [DeFiDonate, MockDepositToken, GovernanceToken],
  // contracts: [
  //     {
  //       contractName: 'DeFiDonate',
  //       web3Contract: new web3.eth.Contract(DeFiDonate.abi, 0x66B8c63849bF0C6Ab133A204d46D975501850bF7) // An instance of a Web3 contract
  //     },
  //     {
  //       contractName: 'MockDepositToken',
  //       web3Contract: new web3.eth.Contract(MockDepositToken.abi, 0x7fBb602f62A3EB1fDDe0E568889a2Eb22248c19A) // An instance of a Web3 contract
  //     }
  //     {
  //       contractName: 'GovernanceToken',
  //       web3Contract: new web3.eth.Contract(GovernanceToken.abi, address) // An instance of a Web3 contract
  //     }
  // ],
  events: {
    DeFiDonate: ["Wrapped"],
  },
  polls: {
    accounts: 1500,
  },
};

export default options;
