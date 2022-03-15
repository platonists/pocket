// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";


// TODO:
// 1. support deposit erc20 token
// 2. add disaster control features
// 3. support contract upgrade
contract Pocket {

    using SafeMath for uint256;

    // pocket information
    string private _name;
    uint256 private _quota;
    uint256 private _openingTime;
    uint256 private _saleDuration;
    uint256 private _lockDuration = 3600 * 24 * 7;      // U.s (a week)
    uint256 private _benefitRatio = 3600 * 24 * 7;      // U.s (a week)

    // sale information
    mapping(address => uint256) private _salesOrder;
    uint256 private _remainQuota;

    // events
    event Deposit(address indexed _user, uint256 _amount);
    event Redeem(address indexed _user, uint256 _amount, uint256 _benefit);

    /**
     * @dev constructor function
     * @param name pocket name
     * @param quota pocket quota
     * @param openingTime (U.s, UTC) pocket start sale timestamp
     * @param saleDuration (U.s) in sale duration, user can deposit local tokens into the pocket. after this, the pocket will be locked 
     * @param lockDuration (U.s) in lock duration, pocket will be locked. after this, user can redeem deposited tokens from pocket and get benefit
     * @param benefitRatio (U.‱) base point for the benefit ratio, 1 BP = 0.01%
     */
    constructor(string memory name, 
                uint256 quota, 
                uint256 openingTime, 
                uint256 saleDuration, 
                uint256 lockDuration, 
                uint256 benefitRatio
    ) {
        _name = name;
        _quota = quota;
        _remainQuota = quota;
        _openingTime = openingTime;
        _saleDuration = saleDuration;
        _lockDuration = lockDuration;
        _benefitRatio = benefitRatio;
    }

    // check pocket during opening period
    modifier isOpening() {
        require(block.timestamp >= _openingTime, "Pocket: contract is not open yet");
        require(block.timestamp < lockingTime(), "Pocket: contract has been locked");
        _;
    }

    // check pocket during release period
    modifier isReleased() {
        require(block.timestamp > _openingTime.add(_saleDuration).add(_lockDuration), "Pocket: contract has not reached the release time");
        _;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function quota() external view returns(uint256) {
        return _quota;
    } 

    // get pocket opening(start sale) time
    function openingTime() external view returns(uint256) {
        return _openingTime;
    }

    // get pocket locking(end sale) time
    function lockingTime() public view returns(uint256) {
        return _openingTime.add(_saleDuration);
    }

    // get pocket release time
    function releaseTime() external view returns(uint256) {
        return _openingTime.add(_saleDuration).add(_lockDuration);
    }

    /**
     * @dev deposit local tokens to pocket
     */
    function deposit(uint256 amount) external isOpening payable {
        require(amount == msg.value, "Pocket: deposit amount is not equal to value");
        require(amount <= _remainQuota, "Pocket: deposit amount is exceeds the remain quota");
        _salesOrder[msg.sender] = _salesOrder[msg.sender].add(amount);
        _remainQuota = _remainQuota.sub(amount);
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev redeem deposited tokens from pocket and get benefit
     */
    function redeem() external isReleased {
        require(_salesOrder[msg.sender] > 0, "Pocket: user has not deposit yet or has redeemed");
        uint256 benefit = _salesOrder[msg.sender].mul(_benefitRatio).div(10000);
        uint256 redeemAmout = _salesOrder[msg.sender].add(benefit);
        require(address(this).balance >= redeemAmout, "Pocket: insufficient balance of this contract");
        payable(msg.sender).transfer(redeemAmout);
        delete _salesOrder[msg.sender];
        emit Redeem(msg.sender, redeemAmout, benefit);
    }

    fallback() external {}
}
