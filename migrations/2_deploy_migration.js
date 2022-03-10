var EasyToken = artifacts.require("EasyToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(EasyToken);
};