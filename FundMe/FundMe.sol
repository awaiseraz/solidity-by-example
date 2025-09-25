// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 1e18;

    mapping(address => uint256) public funders;
    address[] public fundersList;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        return priceFeed.version();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        funders[msg.sender] += msg.value;
        fundersList.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 arrIndex; arrIndex < fundersList.length; arrIndex++) {
            address funder = fundersList[arrIndex];
            // address payable funderPayable = payable(funder);
            // funderPayable.transfer(funders[funder]);
            funders[funder] = 0;
        }

        fundersList = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "CallSuccess Failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
