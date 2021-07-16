// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPancakeRouters.sol";

import "./PriceFeed.sol";

contract Bond is PriceFeed, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 internal PEG_PRICE = 1e18;

    IPancakeRouter02 public router;
    IERC20 public tokenFrom;
    IERC20 public tokenTo;
    address public prizePool;

    constructor(
        address _pancakeRouter,
        address _tokenFrom,
        address _tokenTo,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        router = IPancakeRouter02(_pancakeRouter);
        tokenFrom = IERC20(_tokenFrom);
        tokenTo = IERC20(_tokenTo);
    }

    function _setPrizePool(address _prizePool) public onlyOwner {
        prizePool = _prizePool;
    }

    function pull() public {
        tokenTo.safeTransfer(owner(), tokenTo.balanceOf(address(this)));
    }

    function deposit(uint256 amount) public {
        updatePriceInternal();
        tokenFrom.safeTransferFrom(msg.sender, address(this), amount);

        if (price < PEG_PRICE) {
            uint256 iniTokenToBal = tokenTo.balanceOf(address(this));
            // sell busd
            address[] memory path = new address[](2);
            path[0] = address(tokenFrom);
            path[1] = address(tokenTo);
            tokenFrom.approve(address(router), amount);
            router.swapExactTokensForTokens(amount, 1, path, address(this), block.timestamp);

            // check usdo received
            uint256 balDiff = tokenTo.balanceOf(address(this)).sub(iniTokenToBal);
            // give user Bond tokens
            _mint(msg.sender, balDiff);
        } else {
            // transfer busd to prize pool
            tokenFrom.safeTransfer(prizePool, amount);
            // give user busd equivalent Bonds
            _mint(msg.sender, amount);
        }
    }
}
