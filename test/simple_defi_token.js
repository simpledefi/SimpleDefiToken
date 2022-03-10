const EasyToken = artifacts.require("EasyToken");
const month = 60 * 60 * 24 * 30;
const start_time = 1640455053;
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
let sd;

contract("EasyToken", function (accounts) {

  it("Initial balance should be 0", async () => {
    sd = await EasyToken.deployed();
    let bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
  });

  it("Should have non 0 balance", async () => {
    console.log(await sd.cycleRelease());
    let bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
  });

  it("Should have non 0 balance", async () => {
    let bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
    await sd.cycleRelease();
    bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
    let dist = await sd.distribution("PRIVATE_PLACEMENT");
    console.log(JSON.stringify(dist));
  });

  // 1641405226
  it("Should distribute next month", async () => {
    let bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
    await sd.setBlocktime(start_time+month);
    console.log(await sd.cycleRelease());
    bal = await sd.balanceOf(accounts[0]);
    console.log("Balance of accounts[0] is: " + bal);
    let dist = await sd.distribution("PRIVATE_PLACEMENT");
    console.log(JSON.stringify(dist));
  });

  // it("Can transfer to a second account", async () => {
  //   let bal1 = await sd.balanceOf(accounts[0]);
  //   await sd.transfer(accounts[1], 100);
  //   let bal2 = await sd.balanceOf(accounts[0]);
  //   let bal = await sd.balanceOf(accounts[1]);
  //   console.log("Balance of accounts[1] is: " + bal);
  //   console.log(`transferred accounts[0] is: ${bal2.toNumber()-bal1.toNumber()}`);
  //   assert(bal == 100,"Tokens not transferred");
  //   assert(bal2.toNumber()-bal1.toNumber() == -100,"Tokens not transferred");
  // });

  // it("Shoudn't allow cycleRelease in same month", async () => {
  //   let result = await sd.cycleRelease();
  //   console.log(result);
  // });
});
