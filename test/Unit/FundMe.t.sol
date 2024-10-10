// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployFundMe;
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 1e18}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 1e18);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 ownerInitialBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            address(fundMe.getOwner()).balance,
            initialFundMeBalance + ownerInitialBalance
        );
    }

    function testWithdrawWithAMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax acts as vm.prank and give it a starting eth
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: 1e18}();
        }

        uint256 ownerInitialBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingFundMeBalance == 0);
        assert(
            address(fundMe.getOwner()).balance ==
                initialFundMeBalance + ownerInitialBalance
        );
    }

    function testCheaperWithdrawWithAMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax acts as vm.prank and give it a starting eth
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: 1e18}();
        }

        uint256 ownerInitialBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingFundMeBalance == 0);
        assert(
            address(fundMe.getOwner()).balance ==
                initialFundMeBalance + ownerInitialBalance
        );
    }
}
