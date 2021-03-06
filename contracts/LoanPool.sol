pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"
import "./ILoanPool.sol";
import "./UniversalERC20.sol";

contract LoanPool is ERC20, ERC20Detailed, ILoanPool {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20 public token;
    uint256 public _inLending = 1;

    modifier notInLending {
        require(_inLending == 1);
        _;
    }

    constructor(IERC20 theToken) public ERC20Detailed("LoanPool", "LP", 18) {
        token = theToken;
    }

    function () external payable {
        require(token == IERC20(0) && msg.sender != tx.origin);
    }

    function deposit(
        uint256 value
    )
        public
        notInLending
        payable
    {
        token.universalTransferFrom(msg.sender, address(this), value);

        uint256 amount = value;
        if (totalSupply() > 0) {
            amount = value
                .mul(totalSupply())
                .div(token.universalBalanceOf(address(this)).sub(value));
        }

        _mint(msg.sender, amount);
    }

    function withdrawal(
        uint256 share
    )
        public
        notInLending
    {
        token.universalTransfer(
            msg.sender,
            share
                .mul(token.universalBalanceOf(address(this)))
                .div(totalSupply())
        );

        _burn(msg.sender, share);
    }

    function lend(
        IERC20 tkn,
        uint256 amount,
        ILoanPoolLoaner loaner,
        bytes calldata data
    )
        external
    {
        uint256 expectedBalance = tkn.universalBalanceOf(address(this))
            .add(amount.mul(1e14).div(1e18));
        tkn.universalTransfer(address(loaner), amount);

        _inLending++;
        loaner.inLoan(amount.add(amount.mul(1e14).div(1e18)), data);
        _inLending--;

        require(tkn.universalBalanceOf(address(this)) >= expectedBalance, "Forgot to repay");
    }
}
