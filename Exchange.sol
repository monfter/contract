// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.3;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// Exchange exchange token.
contract Exchange is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // aToken:bToken = 1:1
    uint8 public constant radio = 100;

    IERC20 public aToken;
    IERC20 public bToken;

    address public constant dead = address(0x01);

    constructor(address _aToken, address _bToken
    ) {
        require(_aToken != address(0), "Exchange:Invalid address");
        require(_bToken != address(0), "Exchange:Invalid address");
        aToken = IERC20(_aToken);
        bToken = IERC20(_bToken);
    }

    function exchange(uint256 _amount) public nonReentrant payable {
        require(_amount > 0, "Exchange: Invalid convertible amount");
        aToken.safeTransferFrom(_msgSender(), dead, _amount);
        safeTokenTransfer(_msgSender(), _amount.mul(100).div(radio));
    }

    // Safe token transfer function
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = bToken.balanceOf(address(this));
        require(bal >= _amount, "Exchange: Insufficient convertible balance");

        bToken.safeTransfer(_to, _amount);
        return;
    }

    function recycleTokens(address _address) public onlyOwner {
        require(_address != address(0), "Exchange:Invalid address");
        require(bToken.balanceOf(address(this)) > 0, "Exchange:no tokens");
        bToken.safeTransfer(_address, bToken.balanceOf(address(this)));
    }
}
