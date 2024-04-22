// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address to, uint256 amount) external;

    function totalSupply() external view returns (uint);
}

interface ICurve {
    function add_liquidity(uint[2] memory amounts, uint minAmount) external payable returns(uint);

    function remove_liquidity(uint amount, uint[2] memory minAmounts) external returns(uint[2] memory);
    function remove_liquidity_one_coin(uint amount, int128 i, uint minAmount) external returns(uint);
    function remove_liquidity_imbalance(uint[2] memory amounts, uint maxBurn) external returns(uint);

    function withdraw_admin_fees() external;

    function get_balances() external view returns(uint[2] memory);

    function exchange(int128 i, int128 j, uint256 dx, uint256 dy) external payable returns(uint);
}

contract FallbackTest is Test {

    ICurve constant curve = ICurve(0x94B17476A93b3262d87B9a326965D1E91f9c13E7);
    address constant token = 0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3;

    function setUp() public {
    }

    function testCurveFallback() external {
        // prepare
        uint tokenAmt/* = 11000 ether*/;
        uint ethAmt = 2000 ether;
        deal(address(this), ethAmt);

        // get token via swap, since OETH doesn't have much liquidity elsewhere
        tokenAmt = curve.exchange{value: ethAmt}(0, 1, ethAmt, 1);

        // ====== starting =====
        // log
        uint[2] memory bals = curve.get_balances();
        console.log(bals[0], bals[1]);
        console.log(address(curve).balance, IERC20(token).balanceOf(address(curve)));

        // add
        uint[2] memory amounts;
        amounts[1] = tokenAmt;
        IERC20(token).approve(address(curve), tokenAmt);
        uint liq = curve.add_liquidity(amounts, 1);

        // remove
        amounts[0] = 1;
        amounts[1] = tokenAmt * 99 / 100;
        liq -= curve.remove_liquidity_imbalance(amounts, liq);


        // log
        bals = curve.get_balances();
        console.log(bals[0], bals[1]);
        console.log(address(curve).balance, IERC20(token).balanceOf(address(curve)));
    }

    receive() external payable {
        curve.withdraw_admin_fees();
    }
}
