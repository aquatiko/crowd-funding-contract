// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/*
A crowdfunding smart contract where people can contribute Ether to a project, and 
the funds are released to the project owner only if a funding goal is met within a certain deadline.
If the funding goal is not met, the donated ethers are reverted to donors.
*/
contract CrowdFunding {

    uint public goalAmount;
    uint public numberOfDaysToRunCampaign;
    uint public campaignStartTime;
    bool public isCampaignActive;
    uint constant private secondsInADay = 24 * 60 * 60;

    mapping (address => uint) private amountContributedByDoner;
    address[] donors; 

    constructor(uint _goalAmount, uint _numberOfDaysToRunCampaign){
        goalAmount = _goalAmount;
        numberOfDaysToRunCampaign = _numberOfDaysToRunCampaign;
        campaignStartTime = block.timestamp;
        isCampaignActive = true;
    }

    modifier checkCampaignActive(){
        require(isCampaignActive);
        _;
    } 

    function donate() external payable checkCampaignActive {
        require(address(this).balance - msg.value < goalAmount);
        amountContributedByDoner[msg.sender] += msg.value;
        donors.push(msg.sender);
    }

    function checkAmountToReachGoal() external view returns(uint){
        if(goalAmount < address(this).balance){
            return 0;
        }
        return goalAmount - address(this).balance;
    }

    function settleCampaign() external checkCampaignActive {
        // Either time to run campaign is greater than alloted or goal amount is reached
        require(block.timestamp - campaignStartTime >= numberOfDaysToRunCampaign * secondsInADay || address(this).balance >= goalAmount);
        isCampaignActive = false;
        // revert donations (the caveat here is that gas fee is not reverted, so some ether is lost by user)
        if(address(this).balance < goalAmount){
            for(uint i = 0; i<donors.length; i++){
                payable(donors[i]).transfer(amountContributedByDoner[donors[i]]);
            }
        }
    }
}
