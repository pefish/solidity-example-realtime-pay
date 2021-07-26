// File: @pefish/solidity-lib/contracts/interface/IErc20.sol

pragma solidity >=0.8.0;

interface IErc20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address guy) external view returns (uint256);
    function allowance(address src, address guy) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(
        address src, address dst, uint256 wad
    ) external returns (bool);

//    function mint(address account, uint256 amount) external returns (bool);
//    function burn(uint256 amount) external returns (bool);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}

// File: @pefish/solidity-lib/contracts/library/SafeToken.sol

pragma solidity >=0.8.0;


library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return IErc20(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return IErc20(token).balanceOf(user);
  }

  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// File: contracts/RealTimePay.sol

pragma solidity ^0.8.0;


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
