// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleDefiToken.sol";


contract EasyTokenTest is Test {
    EasyToken public token;
    EasyToken.mintTo[] tokens;

    function setUp() public {
        token = new EasyToken(block.number+500);
    }
    function test000_Token() public view {
        assert(keccak256(bytes(token.symbol())) == keccak256(bytes("EASY")));
        console.log(token.symbol());
    }

    function mint(address _addr,uint _amount, bool _revert) private {
        delete(tokens);
        if (_revert) vm.expectRevert();

        tokens.push(EasyToken.mintTo(_addr,_amount));
        token.mint(tokens);
        console.log("Balance:", _addr, ERC20(address(token)).balanceOf(_addr));
    }

    function test001_MintToOwner() public {
        mint(address(this),1 ether,false);
    }

    function test002_AllowOwnerTransfer() public {
        test001_MintToOwner();
        ERC20(address(token)).transfer(vm.addr(1),.1 ether);
        console.log("Balance 0:", ERC20(address(token)).balanceOf(address(this)));
        console.log("Balance 1:", ERC20(address(token)).balanceOf(vm.addr(1)));
    }

    function test003_DisallowRegularTransfer() public {
        mint(vm.addr(2),1 ether,false);
        vm.expectRevert(EasyToken.functionLocked.selector);
        vm.prank(vm.addr(2));
        token.transfer(vm.addr(3),.1 ether);
        console.log("Balance 0:", ERC20(address(token)).balanceOf(vm.addr(2)));
        console.log("Balance 1:", ERC20(address(token)).balanceOf(vm.addr(3)));

    }

    function test004_AllowAfterBlockRelease() public {
        test003_DisallowRegularTransfer();
        vm.roll(block.number + 510);
        console.log("unlock:", token.releaseBlock(), block.number);
        vm.prank(vm.addr(2));
        token.transfer(vm.addr(3),.1 ether);
        
        console.log("Balance 0:", ERC20(address(token)).balanceOf(vm.addr(2)));
        console.log("Balance 1:", ERC20(address(token)).balanceOf(vm.addr(3)));
}

    function test005_AllowUserTransfer() public {
        test003_DisallowRegularTransfer();
        token.addRelease(vm.addr(2),block.number + 10);
        vm.roll(block.number + 11);
        vm.prank(vm.addr(2));
        token.transfer(vm.addr(3),.5 ether);

        vm.expectRevert(EasyToken.functionLocked.selector);
        vm.prank(vm.addr(3));
        token.transfer(vm.addr(4),.5 ether);

        console.log("Balance 0:", ERC20(address(token)).balanceOf(vm.addr(2)));
        console.log("Balance 1:", ERC20(address(token)).balanceOf(vm.addr(3)));
    }

    function test006_UnrestrictedTransfer() public {
        test003_DisallowRegularTransfer();

        token.releaseToken();

        vm.prank(vm.addr(2));
        token.transfer(vm.addr(3),.5 ether);

        console.log("rBalance 0:", ERC20(address(token)).balanceOf(vm.addr(2)));
        console.log("rBalance 1:", ERC20(address(token)).balanceOf(vm.addr(3)));        
    }

    function test007_DisallowUpdateGreaterThan() public {
        token.addRelease(vm.addr(2),block.number + 10);
        vm.expectRevert(EasyToken.invalidBlockNumber.selector);
        token.addRelease(vm.addr(2),block.number + 20);
    }

    function test008_AllowUpdateLessThan() public {
        token.addRelease(vm.addr(2),block.number + 40);        
        console.log("First:", token.releaseAddresses(vm.addr(2)));

        token.addRelease(vm.addr(2),block.number + 20);
        console.log("Second:",token.releaseAddresses(vm.addr(2)));
    }

    function test009_DisallowOverMinting() public {
        tokens.push(EasyToken.mintTo(token.owner(),500000000 ether));
        vm.expectRevert("Total amount exceeds cap");
        token.mint(tokens);
    }

    function test010_MultipleMints() public {
        
        for (uint i = 2; i < 12; i++) {
            if (i >= 10) 
                mint(vm.addr(i),47000000 ether,true);
            else
                mint(vm.addr(i),47000000 ether,false);
        }
        console.log(token.totalSupply(), token.cap());
        mint(vm.addr(2),token.cap()-token.totalSupply(),false);
    }

    function test011_TranferToSame() public {
        mint(vm.addr(2),47000000 ether,false);
        token.releaseToken();

        vm.prank(vm.addr(2));
        token.transfer(vm.addr(2),1 ether);
        console.log("rBalance 1:", ERC20(address(token)).balanceOf(vm.addr(2)));

    }

    function test012_LotsaTransfers() public {
        test010_MultipleMints();
        vm.roll(block.number+600);
        for (uint i=2; i < 10; i++) {
            vm.prank(vm.addr(i));
            ERC20(address(token)).transfer(vm.addr(i+10),1 ether);
            console.log("Balance :", ERC20(address(token)).balanceOf(vm.addr(i)));
            console.log("Balance :", ERC20(address(token)).balanceOf(vm.addr(i+10)));
        }
    }

    function test013_invalidRelease() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(vm.addr(2));
        token.releaseToken();
    }

    function test014_invalidAdd() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(vm.addr(2));
        token.addRelease(vm.addr(3),block.number + 20);
    }

    function test015_invalidMintTo() public {
        vm.expectRevert("ERC20: mint to the zero address");
        mint(address(0),1 ether, false);
    }

    function test016_testSnapshot() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(vm.addr(2));        
        uint id = token.snapshot();
        console.log("snapshot:", id);

        id = token.snapshot();
        console.log("snapshot:", id);

    }
}
