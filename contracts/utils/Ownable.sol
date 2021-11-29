// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Context.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable, Context {
    address private _owner_;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init() internal initializer {
        address msgSender = _msgSender();
        _owner_ = msgSender;
        emit OwnershipTransferred(address(0), _owner_);

        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == _owner_,
            "Ownable#onlyOwner: SENDER_IS_NOT_OWNER"
        );
        _;
    }

    /**
     * @notice Transfers the ownership of the contract to new address
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable#transferOwnership: INVALID_ADDRESS"
        );
        emit OwnershipTransferred(_owner_, _newOwner);
        _owner_ = _newOwner;
    }

    /**
     * @notice Returns the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner_;
    }
}
