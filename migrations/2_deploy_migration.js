var EasyToken = artifacts.require("EasyToken");
var lib = artifacts.require("BokkyPooBahsDateTimeLibrary");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(lib);
    await deployer.link(lib, EasyToken);
    await deployer.deploy(EasyToken);

};