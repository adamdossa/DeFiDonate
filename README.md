# DeFiDonate

Donate to charity through DeFi

## How It Works

There are two tokens:  
  - CHARITY_DAI - a wrapped version of DAI which has been deposited to Compound (encoded in DeFiDonate.sol).
  - CHARITY_DAI_VOTE - a token which is accrued by holders of CHARITY_DAI (encoded in GovernanceToken.sol).

Both tokens are ERC20 and can be freely transferred.

The process evolves in a series of contiguous epochs, of length `epochLength`.

DAI can be wrapped / unwrapped into CHARITY_DAI at any time, on a 1-1 basis (subject to liquidity in Compound for the unwrapping process).

Holders of CHARITY_DAI accrued CHARITY_DAI_VOTE tokens on the basis of 1 CHARITY_DAI_VOTE token accrued per block per CHARITY_DAI held.

e.g.:
  - deposit `100*10^18` DAI at block 5000000, receive `100*10^18` CHARITY_DAI
  - by block 5001000 your balance of CHARITY_DAI_VOTE will be `1000 * 100*10^18`
  - withdraw `30*10^18` DAI at block 5001000, your CHARITY_DAI balance is now `70*10^18`
  - by block 5001500 your balance of CHARITY_DAI_VOTE will be `(1000 * 100*10^18) + (500 * 70*10^18)`

At any time you can use your CHARITY_DAI_VOTE tokens to vote for the charity you would like to receive interest from DAI which is left on deposit during the next epoch.

You vote by burning your CHARITY_DAI_VOTE and specifying an address you would like to receive the interest.

The winning (most votes) charity as of `coolOffLength` seconds before the end of the epoch, will be the charity paid the total interest in the following epoch. This is to allow people to withdraw their DAI between `(nextEpoch - coolOffLength)` and `nextEpoch` if they don't wish to contribute to the winning charity. Each time a winning charity is chosen, all of the votes are reset to 0.

All code is licensed under an MIT license and has no fees attached (other than gas fees consumed by the network).

## What you can do

Wrap any spare DAI you have as CHARITY_DAI and start to earn interest for a charity.

You can send people CHARITY_DAI as an alternative to DAI, and they can always unwrap it back to DAI (assuming liquidity at Compound).

Accumulate CHARITY_DAI_VOTE tokens as long as you want, and use them to vote for your favourite charity at any time.

If you don't like the charity that has been voted in there will always be a window where you can withdraw funds before any interest associated with those funds is allocated to the chosen charity.

Because of this cool off period, there is little incentive to manipulate voting as a bad actor will just cause everyone to withdraw funds and will have wasted their CHARITY_DAI_VOTE tokens which are burnt during voting.

## Voting

Vote tokens (e.g. CHARITY_DAI_VOTE) are minted by DeFiDonate.sol on a one token (10**18) per DAI deposited, per block.

Vote tokens can be freely transferred.

When voting a user burns CHARITY_DAI_VOTE in order to add it to the tally for voted for charity.

At the end of each voting period, a winning charity is chosen based on the number of CHARITY_DAI_VOTE tokens burnt. This charity has its tally zeroed out, and a new voting period begins.

This means that if you vote (burn) tokens for a charity, you should be incentivised to continue to leave your DAI on deposit so as to earn more CHARITY_DAI_VOTE tokens and be able to add to your charities tally (since losing a voting round does not zero non-winning charities).
