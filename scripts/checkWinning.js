const ethers = require("ethers");
const utils = ethers.utils;

function computeHash(seed, senderAddress, nonce) {
  let packedData = utils
      .solidityKeccak256(
          ["bytes32", "address", "uint256"],
          [seed, senderAddress, nonce]
      ).slice(2);
  // console.log(typeof(packedData));
  // console.log(packedData);
  // packedData = packedData.slice(2);
  // console.log(typeof(packedData));
  // console.log(packedData);
  // packedData = Buffer.from(packedData, "hex");
  // console.log(typeof(packedData));
  // console.log(packedData);
  return packedData;
}

function getWinner(seed, senderAddress, iters) {
  var start = Date.now()
  var winning = "0000000000000000000000000000000000000000000000000000000000000000";
  for(var i = 0; i < iters; i++) {
    var option = computeHash(seed, senderAddress, i);
    // console.log(winning);
    if (-1 == winning.localeCompare(option)) {
      winning = option
    }
  }
  var duration = Date.now() - start;
  console.log(winning);
  console.log("Seconds Elapsed = " + Math.floor(duration/1000));
}
getWinner("0x6065934412ef0fc61e89cd79f060a661298afd081c23d72a6059ca718ad6f87f", "0xca35b7d915458ef540ade6068dfe2f44e8fa733c", 1000000);
