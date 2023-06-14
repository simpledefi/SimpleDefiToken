// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EasyToken is ERC20Capped, ERC20Burnable, ERC20Snapshot, Ownable {
    struct mintTo {
        address to;
        uint256 amount;
        uint256 blocknumber;
    }

    mapping(address=>uint) public releaseAddresses;
    mapping(address=>uint256) public airdropAddresses;
    mapping(address=>uint256) public airdropLocked;

    bool public locked;
    uint public releaseBlock;

    event MintRelease(address indexed to, uint256 value);
    event ReleaseAddressAdd(address _addr, uint _blockNumber);
    event AirdropAddressAdd(address _addr, uint _blockNumber);
    event AirdropUpdate(address _user, uint256 _reduceAmount, uint256 _block);
    event SnapshotMade(uint id);
    event TokenReleased();

    error functionLocked();
    error invalidBlockNumber();
    error invalidAmount();

    /// @title EASY Token Contract
    /// @author Derrick Brabury

    /// @notice Contract Constructor
    /// @param _releaseBlock - Block Number that all the tokens are relased, only set during constructor call
    constructor(uint _releaseBlock) ERC20("SimpleDEFI", "EASY") ERC20Capped(400 * 1e24) {
        releaseBlock = _releaseBlock;
        locked = true;
    }


    /// @notice Adds a user to release transfers at a specified block
    /// @dev Not allowed to increase the release date, just decrease it.
    /// @dev Only allowed to be called by contract owner.
    /// @dev emits address, and block number
    /// @param _addr         - Address of user to allow transfers
    /// @param _blockNumber - block to allow transfers
    function addRelease(address _addr, uint _blockNumber) public onlyOwner {
        uint _rd = releaseAddresses[_addr];
        if (_rd > 0 && _blockNumber > _rd) revert invalidBlockNumber();
        releaseAddresses[_addr] = _blockNumber;
        emit ReleaseAddressAdd(_addr, _blockNumber);
    }

    /// @notice Allows unrestricted transfers
    /// @dev Only can set locked to false, no abilitiy to re-lock the contract
    /// @dev Only allowed to be called by contract owner.
    /// @dev emits TokenReleased
    function releaseToken() external onlyOwner {
        locked = false;
        emit TokenReleased();
    }
    /// @notice Mints tokens to an array of users and amounts
    /// @param _mintTo - structure array of users and amounts    
    /// @dev Only allowed to be called by contract owner.
    /// @dev emits address, and amount minted
    function mint(mintTo[] calldata _mintTo) external onlyOwner{
        uint subtotal;
        for (uint i = 0; i < _mintTo.length; i++) {
            subtotal += _mintTo[i].amount;         
        }
        require(subtotal + totalSupply() <= cap(), "Total amount exceeds cap");
        for (uint i = 0; i < _mintTo.length; i++) {
            _mint(_mintTo[i].to, _mintTo[i].amount);
            if (_mintTo[i].blocknumber > 0) {
                addRelease(_mintTo[i].to,_mintTo[i].blocknumber);
            }
        }
        emit MintRelease(address(this),subtotal);
    }

    /// @notice airdops tokens to an array of users and amounts and locks the tokens to a specific block 
    /// @param _mintTo - structure array of users and amounts    
    /// @dev Only allowed to be called by contract owner.
    /// @dev emits address, and amount minted
    function airdrop(mintTo[] calldata _mintTo) external onlyOwner{
        uint subtotal;
        for (uint i = 0; i < _mintTo.length; i++) {
            subtotal += _mintTo[i].amount;         
        }
        require(subtotal + totalSupply() <= cap(), "Total amount exceeds cap");
        for (uint i = 0; i < _mintTo.length; i++) {
            _mint(_mintTo[i].to, _mintTo[i].amount);

            if (airdropAddresses[_mintTo[i].to] < block.number) //clears out any old airdrops if they are expired
                airdropLocked[_mintTo[i].to] = _mintTo[i].amount;
            else
                airdropLocked[_mintTo[i].to] += _mintTo[i].amount;
                
            airdropAddresses[_mintTo[i].to] = _mintTo[i].blocknumber;
            emit AirdropAddressAdd(_mintTo[i].to, _mintTo[i].blocknumber);
        }
        emit MintRelease(address(this),subtotal);
    }

    /// @notice Allow admin to decrease release time of airdropped user
    /// @param _user - the address of the user to release tokens
    /// @param _block - the block to release the token
    /// @dev emits user and block to be released
    function updateAirdrop(address _user, uint _reduceAmount, uint _block) public onlyOwner {
        if (_block > 0) {
            if (airdropAddresses[_user] > 0 && airdropAddresses[_user] > _block) revert invalidBlockNumber();
            airdropAddresses[_user] = _block;        
        }

        if (_reduceAmount > 0) {
            if (_reduceAmount > airdropLocked[_user]) revert invalidAmount();
            airdropLocked[_user] -= _reduceAmount;
        }
        emit AirdropUpdate(_user, _reduceAmount, _block);
    }

    /// @notice Transfers tokens from one address to anothera, but locks until specified block number
    /// @param _to - address to transfer tokens to 
    /// @param _amount - amount of tokens to transfer
    /// @param _blocknumber - block number until lock is released
    function transfer(address _to, uint _amount, uint _blocknumber) public onlyOwner {
        if (_blocknumber>0) addRelease(_to, _blocknumber);
        super.transfer(_to, _amount);
    }

    /// @notice Part of OpenZeppelin contract to take snapshot of token holders
    /// @return - returns snapshot id
    function snapshot() public onlyOwner returns (uint){
        uint _id = _snapshot();
        emit SnapshotMade(_id);
        return _id;
    }

    /// @notice Part of OpenZeppelin contract to execute before a transfer. 
    /// @dev Checks if transfer functionality is locked
    /// @param _from   - address transferring tokens from
    /// @param _to     - address transferring tokens to
    /// @param _amount - number of tokens being transferred
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Snapshot)
    {
        if (locked == true && block.number <= releaseBlock && (releaseAddresses[_from] == 0 || block.number <= releaseAddresses[_from]) && msg.sender != owner()) revert functionLocked();      
        if (airdropAddresses[_from] > 0 && block.number < airdropAddresses[_from]) {
            if (_amount > balanceOf(_from) - airdropLocked[_from]) revert invalidAmount();
        }
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    /// @notice Internal function that actually mints the tokens
    /// @param to    - address to mint tokens to
    /// @param value - number of tokens to mint
    /// @dev emits address and amount of tokens minted
    function _mint(address to, uint256 value) internal override (ERC20Capped,ERC20) {
        ERC20Capped._mint(to, value);
        emit MintRelease( to, value);
    }
}
