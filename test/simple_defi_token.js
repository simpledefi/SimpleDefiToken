const EasyToken = artifacts.require("EasyToken");
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
let sd;
let TOTALSUPPLY = 400000000;

contract("EasyToken", function (accounts) {

  it("Initial balance should be 0", async () => {
    sd = await EasyToken.deployed();
    let bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
  });

  it("should create mint to multiple users", async () => {
    a = []
    for (const account of accounts) {
      a.push({to: account, amount:(TOTALSUPPLY / 10).toString() + "000000000000000000"});
    }

    console.log(JSON.stringify(a));
    let tx = await sd.mint(a);
    console.log("Mint tx: " + tx);
    let total = 0;
    for(let i = 0; i < accounts.length; i++) {
      let bal = await sd.balanceOf(accounts[i]);
      console.log(`Balance of accounts[${i}] is: ` + bal);
      total += bal/1e18;
    }
    console.log("Total supply: " + total);
  });

  it("should not allow any more minting", async () => {
    try {
      a = [{to: accounts[0], amount:1}];
      await sd.mint(a);
      assert(false, "Minting should not be allowed");
    }
    catch(e) {
      console.log(e.data[Object.keys(e.data)[0]].reason);
    }
  });

  it("Should take a snapshot", async () => {
    let snap = await sd.snapshot();
    console.log("Snapshot: " + JSON.stringify(snap));
  });
});
