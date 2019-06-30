import MyComponent from "./MyComponent";
import { drizzleConnect } from "drizzle-react";

const mapStateToProps = state => {
  return {
    state: state,
    accounts: state.accounts,
    DeFiDonate: state.contracts.DeFiDonate,
    GovernanceToken: state.contracts.GovernanceToken,
    drizzleStatus: state.drizzleStatus,
  };
};

const MyContainer = drizzleConnect(MyComponent, mapStateToProps);

export default MyContainer;
