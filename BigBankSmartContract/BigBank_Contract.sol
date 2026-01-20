// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IBank {
    function deposit() external payable;
    function getTopDepositors() external view returns (address[3] memory, uint[3] memory);
    function withdraw() external;
}

contract Bank is IBank {
    address public admin;
    mapping(address => uint) public deposits;
    uint8 private constant TOP_COUNT = 3;
    address[TOP_COUNT] public topDepositors;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable virtual {
        _handleDeposit();
    }

    function deposit() external payable virtual {
        _handleDeposit();
    }

    function _handleDeposit() internal {
        deposits[msg.sender] += msg.value;
        _updateTopDepositors(msg.sender);
    }

    // 更新排名
    function _updateTopDepositors(address depositor) internal {
        uint depositorBalance = deposits[depositor];

        // 如果之前在排名里
        for (uint8 i=0; i<TOP_COUNT; i++) {
            if (topDepositors[i] == depositor) {
                _updateRanking();
                return;
            }
        }

        // 如果之前不在排名里，则将他插入到比他小的前面
        for (uint8 i=0; i<TOP_COUNT; i++) {
            address currentAddr = topDepositors[i];
            if (currentAddr == address(0) || depositorBalance > deposits[currentAddr]) {
                for (uint8 j=2; j>i; j--) {
                    topDepositors[j] = topDepositors[j-1];
                }
                topDepositors[i] = depositor;
                break;
            }
        }
    }

    // 更新排名
    function _updateRanking() internal {
        address[TOP_COUNT] memory top = topDepositors;
        for(uint8 j=TOP_COUNT-1; j>0; j--){
            for(uint8 i=0; i<j; i++){
                if(deposits[top[i]] < deposits[top[i+1]]){
                    address tmp = top[i];
                    top[i] = top[i+1];
                    top[i+1] = tmp;
                }
            }
        }
        topDepositors = top;
    }

    function getTopDepositors() external view returns (address[3] memory, uint[3] memory) {
        uint[TOP_COUNT] memory amounts;
        for(uint8 i=0; i<TOP_COUNT; i++){
            amounts[i] = deposits[topDepositors[i]];
        }
        return (topDepositors,amounts);
    }

    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

}


// BigBank 继承Bank，多个一个修改管理员的功能（必须是该合约部署者）
contract BigBank is Bank {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    // 函数修改器modifier要求存款金额大于0.001 ether才能存款
    modifier depositAmountGreaterThan001 () {
        require(msg.value > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    // 只有管理员才能执行
    modifier isOwner () {
        require(msg.sender == owner, "Only owner can do this");
        _;
    }

    function deposit() external payable override depositAmountGreaterThan001{
        _handleDeposit();
    }

    receive() external payable override depositAmountGreaterThan001{
        _handleDeposit();
    }

    function changeAdmin(address newAdmin) external isOwner{
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }
}

// 该合约用于：Admin合约充当BigBank合约的管理员（部署人=>Admin合约=>BigBank合约）
//      提取BigBank合约的存款到该合约地址（前提：BigBank合约的管理员改为该合约地址）；
//      再将该合约地址的金额转给合约部署者；
contract Admin {
    address public immutable admin;

    constructor() {
        admin = msg.sender;
    }

    // 添加receive函数以接收ETH
    receive() external payable {

    }

    // 只有管理员才能执行
    modifier isAdmin () {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    // 修改adminWithdraw函数，确保Bank合约的admin是Admin合约地址
    function adminWithdraw(IBank bank) external isAdmin {
        bank.withdraw();
    }

    // 添加函数让Admin合约的admin可以提取合约中的ETH
    function withdrawToOwner() external isAdmin {
        uint balance = address(this).balance;
        require(balance > 0, "no balance to withdraw");
        (bool success, ) = admin.call{value: balance}("");
        require(success , "withdraw failed");
    }

}

