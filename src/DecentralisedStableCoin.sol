// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//err custom,hemat gas bro wkkw
error DecentralizedStableCoin__MustBeMoreThanZero();
error DecentralizedStableCoin__BurnAmountExceedsBalance();
error DecentralizedStableCoin__NotZeroAddress();

contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    //constructor , 1 time run
    constructor() ERC20("DecentralizedCoin", "DSC") Ownable(msg.sender) {}

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) revert DecentralizedStableCoin__NotZeroAddress();
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount == 0) revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        if (balance < _amount) revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        super.burn(_amount); // verify burnin the token
    }
}

