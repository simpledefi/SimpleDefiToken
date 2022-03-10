// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract EasyToken is ERC20Capped, ERC20Burnable, ERC20Snapshot, Ownable {
    struct mintTo {
        address to;
        uint256 amount;
    }

    event MintRelease(address indexed to, uint256 value);
    constructor() ERC20("SimpleDEFI", "EASY") ERC20Capped(400000000*1e18) {}

    function mint(mintTo[] memory _mintTo) public onlyOwner{
        uint subtotal;
        for (uint i = 0; i < _mintTo.length; i++) {
            subtotal += _mintTo[i].amount;         
        }
        require(subtotal + totalSupply() <= cap(), "Total amount exceeds cap");
        for (uint i = 0; i < _mintTo.length; i++) {
            _mint(_mintTo[i].to, _mintTo[i].amount);
        }
    }

    function snapshot() public onlyOwner returns (uint){
        return _snapshot();
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function _mint(address to, uint256 value) internal override (ERC20Capped,ERC20) {
        ERC20Capped._mint(to, value);
        emit MintRelease( to, value);
    }
}
