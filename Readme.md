```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Trap {
    function collect() external returns (bytes memory);
    function shouldRespond(bytes calldata data) external view returns (bool, bytes memory);
}```
