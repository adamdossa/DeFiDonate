import React from "react";
import { drizzleReactHooks } from 'drizzle-react'

import {
  AccountData,
  ContractData,
  ContractForm,
} from "drizzle-react-components";

import logo from "./logo.png";

export default (props) => {

  let accounts = props.accounts;
  console.log(props.DeFiDonate);
  return <div className="App">
    <div>
      <img src={logo} alt="drizzle-logo" />
      <h1>DeFiDonate</h1>
      <p>Donate to charity through DeFi on Ethereum.</p>
    </div>

    <div className="section">
      <h2>Active Account</h2>
      <AccountData accountIndex={0} units="ether" precision={3} />
    </div>

    <div className="section">
      <h2>Account Details</h2>
      <p>
        <strong>CHARITY_DAI (Wrapped DAI) Address: </strong>
        <ContractData contract="DeFiDonate" method="myAddress" />
      </p>
      <p>
        <strong>CHARITY_DAI (Wrapped DAI) Balance: </strong>
        <ContractData contract="DeFiDonate" method="balanceOf" methodArgs={[accounts[0]]} />
      </p>
      <p>
        <strong>CHARITY_DAI_VOTE (Voting Token) Address: </strong>
        <ContractData contract="DeFiDonate" method="governanceToken" />
      </p>
      <p>
        <strong>CHARITY_DAI_VOTE (Voting Token) Balance: </strong>
        <ContractData contract="GovernanceToken" method="balanceOf" methodArgs={[accounts[0]]} />
      </p>
      <p>
        <strong>DAI Balance: </strong>
        <ContractData contract="MockDepositToken" method="balanceOf" methodArgs={[accounts[0]]} />
      </p>
    </div>
    <div className="section">
      <h2>Charity Details</h2>
      <p>
        <strong>Current Charity: </strong>
        <ContractData contract="DeFiDonate" method="governanceToken" />
      </p>
      <p>
        <strong>Next Epoch (Charity Rolls Over): </strong>
        <ContractData contract="DeFiDonate" method="nextEpoch" />
      </p>
      <p>
        <strong>Next Chosen Charity: </strong>
        <ContractData contract="DeFiDonate" method="chosenCharity" />
      </p>
    </div>
    <div className="section">
      <h2>Charity Voting</h2>
      <p>
        <strong>Winning Charity: </strong>
        <ContractData contract="DeFiDonate" method="largestCharity" />
      </p>
      <p>
        <strong>Votes For Winning Charity: </strong>
        <ContractData contract="DeFiDonate" method="largestVote" />
      </p>
      <p>
        <strong>Vote For Charity: </strong>
      </p>
      <ContractForm contract="DeFiDonate" method="vote" />
    </div>
    <div className="section">
      <h2>Wrap / Unwrap</h2>
      <p>
        <strong>Approve DAI: </strong>
        <ContractForm contract="DeFiDonate" method="approve" />
      </p>
      <p>
        <strong>Wrap DAI: </strong>
        <ContractForm contract="DeFiDonate" method="wrap" />
      </p>
      <p>
        <strong>Unwrap DAI: </strong>
        <ContractForm contract="DeFiDonate" method="unwrap" />
      </p>
    </div>
  </div>;
}
