// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";

contract BankScript is Script {
    Bank public bank;

    function setUp() public {}

    function run() public {
        // 从.env 文件中加载私钥
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        
        // 使用指定账户签署交易并在链上广播交易
        vm.startBroadcast(deployer);

        // 创建合约的交易将被 Forge 在链上广播并完成合约的部署
        bank = new Bank();

        vm.stopBroadcast();
    }
}
