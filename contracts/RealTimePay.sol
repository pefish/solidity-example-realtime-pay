// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeToken } from "@pefish/solidity-lib/contracts/library/SafeToken.sol";

contract RealTimePay {
    struct PayInfo {
        address token;
        uint256 amount;
        uint256 payTime;
        uint256 pickedUpAmount;
    }

    mapping(address => PayInfo) public pays;

    // 支付月薪
    function pay (address token, uint256 amount, address to) external payable {
        require(to != address(0), "to address must not be 0");
        require(amount != 0, "amount must not be 0");
        require(pays[to].amount == 0 && pays[to].payTime + 30 days <= block.timestamp, "last order have not be finished");

        if (token == address(0)) {  // 代表支付的是 BNB
            require(msg.value >= amount, "value not enough");
            payable(msg.sender).transfer(msg.value - amount);
        } else {  // 支付的是 token 代币
            SafeToken.safeTransferFrom(token, msg.sender, address(this), amount);  // 需要先授权
        }
        pays[to].token = token;
        pays[to].amount += amount;
        pays[to].payTime = block.timestamp;
    }

    // 得到可以提取的薪资数量
    function canPickUpAmount () public view returns (address, uint256) {
        require(pays[msg.sender].amount > 0, "remain amount is 0");
        require(pays[msg.sender].pickedUpAmount < pays[msg.sender].amount, "nothing to pick up");
        require(block.timestamp > pays[msg.sender].payTime, "it is not time to pick up");

        return (
            pays[msg.sender].token,
            pays[msg.sender].amount / 30 days * (block.timestamp - pays[msg.sender].payTime) - pays[msg.sender].pickedUpAmount
        );
    }

    // 提取薪资
    function pickUp () external {
        (address token, uint256 amount) = canPickUpAmount();
        require(amount > 0, "nothing to pick up");

        pays[msg.sender].pickedUpAmount += amount;
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            SafeToken.safeTransferFrom(token, address(this), msg.sender, amount);
        }

    }
}
