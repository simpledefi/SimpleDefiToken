var EasyToken = artifacts.require("EasyToken");
function amt(val, decimals=18) {
    return  parseFloat(val).toFixed(decimals).replace(".","").toString();
}

module.exports = async function(deployer, network, accounts) {
    var sd = await EasyToken.deployed();

    let a = [];
    a.push({to: "0x22E1053dA1e3399079e6AA1Ad232b1C4527A8511", amount: amt(12000000)}); //SDFI - Airdrops	
    a.push({to: '0x3D44182E6e6556F4F93b7e5b106093721d780d00', amount: amt(80000000)}); //SDFI - Core Team	
    a.push({to: '0x732Eb006C91d2EeA79cBAe8d7624491a9029aa99', amount: amt(40000000)}); //SDFI - Growth	
    a.push({to: '0x6BCF68da9c2b6ed1eb15813a7549b4ea4dacB5e2', amount: amt(4000000)}); //SDFI - LP	
    a.push({to: '0x87B0f907576d8480a036460Da9849975e7763d48', amount: amt(4000000)}); //SDFI - MM	
    a.push({to: '0xea822B4cF783563E83F5A69aD2abb1B63fdB7F86', amount: amt(40000000)}); //SDFI - Private Sale	
    // a.push({to: '0x1674A020007751E7Cf671dCBEf0d4D859bFB35eb', amount: amt(30000000)}); //SDFI - Public Sale	
    a.push({to: '0xE357184c22aa24f792cD03C4B0b25FE9AE4b1823', amount: amt(160000000)}); //SDFI - Rewards	
    // a.push({to: '0x9334BbaD9B788345b33C569df84A8CE74a56312F', amount: amt(30000000)}); //SDFI - Strategic Sale	

    console.log(JSON.stringify(a));
    let tx = await sd.mint(a);
    console.log("Mint tx: " + tx);
    for (i in a) {
        let bal = await sd.balanceOf(a[i].to);
        console.log(`Balance of ${a[i].to} is: ` + bal);
    }
};