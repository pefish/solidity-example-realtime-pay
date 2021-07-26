const RealTimePay = artifacts.require("RealTimePay");

module.exports = async function (deployer,network, accounts) {
  await deployer.deploy(RealTimePay);
} as Truffle.Migration;

export {};