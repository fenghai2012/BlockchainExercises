// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Bank {
    address public immutable ADMIN;
    mapping (address => uint) public deposits;
    address[3] public topDepositors;
    uint8 private constant TOP_COUNT = 3;

    constructor() {
        ADMIN = msg.sender;
    }

    receive() external payable {
        _handleDeposit();
    }

    function deposit() external payable {
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
        uint[3] memory amounts;
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            amounts[i] = deposits[topDepositors[i]];
        }
        return (topDepositors, amounts);
    }

    // 取款
    function withdraw() external {
        require(msg.sender == ADMIN, "Only admin can withdraw");
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = ADMIN.call{value: balance}("");
        require(success, "Withdraw failed");
    }

}