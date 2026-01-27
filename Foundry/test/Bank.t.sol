// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    address public user4;

    // 在每个测试用例执行前设置测试环境
    function setUp() public {
        // 设置管理员地址
        admin = address(this);
        
        // 创建测试用户地址
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        
        // 给测试用户一些ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        
        // 部署Bank合约
        bank = new Bank();
    }

    function testDeposit() public {
        assertEq(bank.deposits(user1), 0);

        uint256 depositAmount = 1 ether;
        vm.prank(user1);
        bank.deposit{value: depositAmount}();

        assertEq(bank.deposits(user1), depositAmount);

        uint256 secondDepositAmount = 0.5 ether;
        vm.prank(user1);
        bank.deposit{value: secondDepositAmount}();

        assertEq(bank.deposits(user1), depositAmount+secondDepositAmount);
        
    }

    function testTopDepositors() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();

        (address[3] memory topAddrs, uint[3] memory amounts) = bank.getTopDepositors();
        assertEq(topAddrs[0], user2);
        assertEq(amounts[0], 2 ether);
        assertEq(topAddrs[1], user1);
        assertEq(amounts[1], 1 ether);
        assertEq(topAddrs[2], address(0));
        assertEq(amounts[2], 0);
    }

    function testWithDrawOnlyAdmin() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        assertEq(address(bank).balance, 1 ether);

        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        bank.withdraw();

        address bankAdmin = bank.ADMIN();
        uint256 adminBalanceBefore = bankAdmin.balance;

        console.log("bankAdmin", bankAdmin);
        console.log("admin", admin);
        vm.prank(bankAdmin);
        bank.withdraw();

        uint256 adminBalanceAfter = bankAdmin.balance;

        assertEq(adminBalanceAfter - adminBalanceBefore, 1 ether);
        assertEq(address(bank).balance, 0);
    }

    // 添加receive函数以接收ETH，避免转账失败（该合约需要接收ETH）
    receive() external payable {}
}
