import DeFiDonate from "./contracts/DeFiDonate.json";
import MockDepositToken from "./contracts/MockDepositToken.json";
//import GovernanceToken from "./contracts/GovernanceToken.json";

const options = {
  web3: {
    block: false,
    fallback: {
      type: "ws",
      url: "ws://127.0.0.1:9545",
    },
  },
  contracts: [DeFiDonate, MockDepositToken],
  events: {
    DeFiDonate: ["Wrapped"],
  },
  polls: {
    accounts: 1500,
  },
};

export default options;
