//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    /**
     * @dev Sets the values for {name} and {symbol}.
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20("CBC GEM", "CBCGEM") {
    }

    /** @dev Allows the only owner to mint
     * Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}