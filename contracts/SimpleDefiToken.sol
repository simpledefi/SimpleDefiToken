// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/BokkyPooBahsDateTimeLibrary.sol";

/// @custom:security-contact dev@simpledefi.io
contract EasyToken is ERC20, ERC20Burnable, ERC20Snapshot, Pausable, AccessControl {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
            
    uint public constant TOTAL_SUPPLY = 400000000;
    uint blocktime;
    bool tokenLive = false;

    struct dist {
        uint max_supply;
        uint current_supply;
        uint start_dist;
        uint last_dist;
        uint multiplier;
        uint cycles;
        uint nextCycle;
        uint cycleDay;
        address mintTo;
    }

    mapping (string=>dist) public distribution;

    event MintRelease(string _type, address indexed to, uint256 value);

    constructor()   ERC20("EasyToken", "EASY"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        reset_token();
    }

    function reset_token() private {
        require(tokenLive == false, "Token is already live");

        distribution["PRIVATE_PLACEMENT"] = dist({
            max_supply: 40000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 6666666,
            multiplier: 100,
            cycles: 6,
            cycleDay: 1,
            nextCycle: 0,
            mintTo: msg.sender
        });

        distribution["COMMUNITY_REWARDS"] = dist({
            max_supply: 160000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 8000000,
            multiplier: 95,
            cycles: 48,
            cycleDay: 1,
            nextCycle: 0,
            mintTo: msg.sender
        });

        distribution["TEAM_REWARDS"] = dist({
            max_supply: 80000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 6666666,
            multiplier: 100,
            cycles: 12,
            cycleDay: 1,
            nextCycle: 0,
            mintTo: msg.sender
        });

        distribution["PUBLIC_SALE"] = dist({
            max_supply: 60000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 0,
            multiplier: 0,
            cycles: 1,
            cycleDay: 0,
            nextCycle: 0,
            mintTo: msg.sender
        });

        distribution["AIR_DROPS"] = dist({
            max_supply: 12000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 0,
            multiplier: 0,
            cycles: 1,
            cycleDay: 0,
            nextCycle: 0,
            mintTo: msg.sender
        });

        distribution["GROWTH_FUND"] = dist({
            max_supply: 48000000,
            current_supply: 0,
            last_dist: 0,
            start_dist: 0,
            multiplier: 0,
            cycles: 1,
            cycleDay: 0,
            nextCycle: 0,
            mintTo: msg.sender
        });
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    //remove for production
    function setBlocktime(uint newBlocktime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenLive == false, "Token is already live");
        blocktime = newBlocktime;
    }

    function setLive() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenLive == false, "Token is already live");

        reset_token();
        
        tokenLive = true;
        blocktime = 0;
    }

    function cycleRelease() public onlyRole(MINTER_ROLE) {
        string[6] memory dists = ['PRIVATE_PLACEMENT', 'COMMUNITY_REWARDS', 'TEAM_REWARDS','PUBLIC_SALE', 'AIR_DROPS', 'GROWTH_FUND'];      
        uint _blocktime = blocktime==0?block.timestamp:blocktime;
        uint day = BokkyPooBahsDateTimeLibrary.getDay(_blocktime);

        uint mintAmount;

        for (uint i = 0;i<6;i++) {
            if (distribution[dists[i]].cycles > 0 && distribution[dists[i]].current_supply < distribution[dists[i]].max_supply) {
                if ((distribution[dists[i]].nextCycle <= _blocktime && day >= distribution[dists[i]].cycleDay) || distribution[dists[i]].multiplier == 0) {
                    if (distribution[dists[i]].multiplier == 0) {
                        mintAmount = distribution[dists[i]].max_supply;
                    }
                    else {
                        mintAmount = distribution[dists[i]].last_dist == 0? distribution[dists[i]].start_dist:(distribution[dists[i]].last_dist * distribution[dists[i]].multiplier) / 100;
                    }

                    uint remaining = distribution[dists[i]].max_supply - (distribution[dists[i]].current_supply + mintAmount);
                    if (remaining < 100) {
                        mintAmount += remaining;
                    }
                    

                    if (distribution[dists[i]].current_supply + mintAmount <= distribution[dists[i]].max_supply && totalSupply() + mintAmount <= TOTAL_SUPPLY) {
                        distribution[dists[i]].last_dist = mintAmount;
                        distribution[dists[i]].current_supply += mintAmount;
                        distribution[dists[i]].nextCycle = BokkyPooBahsDateTimeLibrary.addMonths(_blocktime,1);
                        
                        if (mintAmount>0) distribution[dists[i]].cycles--;
                        _mint(distribution[dists[i]].mintTo, mintAmount);                    
                        emit MintRelease(dists[i],distribution[dists[i]].mintTo, mintAmount);
                    }
                }
            }
        }
    }
}
