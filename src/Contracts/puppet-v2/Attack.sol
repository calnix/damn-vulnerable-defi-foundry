// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UniswapV2Library} from "./UniswapV2Library.sol";

contract Attack {
    function test(address tokenA, address tokenB) public pure returns (address, address) {
        UniswapV2Library.sortTokens(tokenA, tokenB);
    }
}
