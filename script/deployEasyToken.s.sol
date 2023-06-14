// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SimpleDefiToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract deployEasyTokenScript is Script {
    uint _releaseBlock = 31378512;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("privateKey");
        vm.startBroadcast(deployerPrivateKey);

        EasyToken et = new EasyToken(_releaseBlock);
        console.log(address(et));
        vm.stopBroadcast();
        verifyContract("EasyToken",address(et));
    }


    function verifyContract(string memory _facetName, address _addr) internal  {
        console.log("Verify:",_facetName,_addr);
        string [] memory cmd = new string[](9);
        cmd[0] = "forge";
        cmd[1] = "verify-contract";
        cmd[2] = Strings.toHexString(uint160(_addr), 20);        
        cmd[3] = _facetName;
        cmd[4] = "DJRAEIG3XK1WF51RWG67NKMJQ8DKSN4S1M";
        cmd[5] = "--verifier-url";
        cmd[6] = "https://api.bscscan.com/api";
        cmd[7] = "--constructor-args";
        cmd[8] = "0x0000000000000000000000000000000000000000000000000000000001decc50";

        for(uint i=0;i<cmd.length;i++)
            console.log(i,cmd[i]);

        bytes memory res = vm.ffi(cmd);
        console.log(string(res));
    }

}

