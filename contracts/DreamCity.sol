pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public ownerTwo;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == ownerTwo);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwnerTwo(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(ownerTwo, _newOwner);
        ownerTwo = _newOwner;
    }

}

/**
 * @title InvestorStorage
 */
contract InvestorStorage is Ownable {
    using SafeMath for uint256;

    uint256 public countInvestors;
    uint256 public amountLastToken = 10;
    uint256 public percentToLastRemainingToken = 1;
    uint256 public percentToLastToken = 1;
    uint256 public totalPrize = 0;

    bool public isDemo;
    bool public stopBuyTokens;

    uint256 public startTime;
    uint256 public simulateDate;
    uint256 public totalEthPerHouse;

    struct Investor {
        uint256 investmentEth;
        uint256 refundEth;
        uint256 amountToken;
        uint256 paymentTime;
        uint256 sellTime;
        uint256 numberHouse;
    }

    struct PaidTokenLastDay {
        address investor;
        uint256 amountToken;
        uint256 paymentTime;
    }

    PaidTokenLastDay[] arrayPaidTokenLastDay;

    mapping (address => Investor) investors;
    mapping (uint256 => uint256) public paidPerDay;
    mapping (address => bool) admins;

    event TokenPurchaise(address indexed investor, uint256 paymentTime, uint256 amountEth, uint256 amountToken);
    event ChangeTime(uint256 _newDate, uint256 simulateDate);

    constructor() public {
        isDemo = false;
    }

    function investorMainInfo(address _investor) public view returns (
        uint256 investmentEth, uint256 refundEth,
        uint256 amountToken, uint256 numberHouse
    ) {
        Investor storage inv = investors[_investor];

        investmentEth = inv.investmentEth;
        refundEth = inv.refundEth;
        amountToken = inv.amountToken;
        numberHouse = inv.numberHouse;
    }

    function investorTimeInfo(address _investor) public view returns (
        uint256 paymentTime, uint256 sellTime
    ) {
        Investor storage inv = investors[_investor];

        paymentTime = inv.paymentTime;
        sellTime = inv.sellTime;
    }

    function newInvestor(
        address _investor, uint256 _investment, uint256 _amountToken,
        uint256 _paymentTime, uint256 _currentHouse
    ) internal returns (bool) {
        if (!checkNewInvestor(_investor)) {
            return false;
        }
        addFundToInvestor(_investor, _investment, _amountToken, _paymentTime, _currentHouse);
        countInvestors++;
        return true;
    }

    function checkNewInvestor(address _investor) internal view returns (bool) {
        Investor storage inv = investors[_investor];
        if (inv.paymentTime > 0 && inv.investmentEth > 0) {
            return false;
        }
        return true;
    }

    function addFundToInvestor(
        address _investor, uint256 _investment, uint256 _amountToken,
        uint256 _paymentTime, uint256 _currentHouse
    ) internal {
        Investor storage inv = investors[_investor];
        inv.investmentEth = inv.investmentEth.add(_investment);
        inv.amountToken = inv.amountToken.add(_amountToken);
        inv.paymentTime = _paymentTime;
        inv.numberHouse = _currentHouse;
        setPaidLastInvestorPerDay(_investor, _amountToken, _paymentTime);
        totalEthPerHouse = totalEthPerHouse.add(_investment);
        uint256 numberDay = getNumberDay(getCurrentDate());
        if (!stopBuyTokens) {
            paidPerDay[numberDay] = paidPerDay[numberDay].add(_amountToken);
        }
        emit TokenPurchaise(_investor, _paymentTime, _investment, _amountToken);
    }

    function setPaidLastInvestorPerDay(address _investor, uint256 _amountToken, uint256 _paymentTime) internal {
        require(_investor != address(0));
        require(_amountToken >= 0);
        require(_paymentTime >= 0);

        fixArrayPaidTokenLastDay();


        arrayPaidTokenLastDay.push(PaidTokenLastDay({
            investor : _investor,
            amountToken : _amountToken,
            paymentTime : _paymentTime
            }));

    }

    function fixArrayPaidTokenLastDay() internal returns (uint256 countElem) {
        countElem = 0;
        uint256 today = getCurrentDate();
        uint256 numberTodayDay = getNumberDay(today);

        uint256 currentPaymentTime;
        uint256 currentNumberDay;

        uint256 lengthArray = arrayPaidTokenLastDay.length;
        if (lengthArray > 1) {
            while (countElem < lengthArray) {
                currentPaymentTime = arrayPaidTokenLastDay[0].paymentTime;
                currentNumberDay = getNumberDay(currentPaymentTime);
                if (numberTodayDay > currentNumberDay) {
                    for (uint i = 0; i<arrayPaidTokenLastDay.length-1; i++){
                        arrayPaidTokenLastDay[i] = arrayPaidTokenLastDay[i+1];
                    }
                    delete arrayPaidTokenLastDay[arrayPaidTokenLastDay.length-1];
                    arrayPaidTokenLastDay.length--;
                }
                countElem++;
            }
        }
    }

    function getMemberArrayPaidTokenLastDay(uint256 index) public view returns (
        address investor, uint256 amountToken, uint256 paymentTime
    ) {
        require(index < arrayPaidTokenLastDay.length && index >= 0);
        investor = arrayPaidTokenLastDay[index].investor;
        amountToken = arrayPaidTokenLastDay[index].amountToken;
        paymentTime = arrayPaidTokenLastDay[index].paymentTime;
    }

    function getTimeLastInvestor() public view returns (uint256 lastTimePaid) {
        lastTimePaid = 0;
        if (arrayPaidTokenLastDay.length > 0) {
            lastTimePaid = arrayPaidTokenLastDay[arrayPaidTokenLastDay.length - 1].paymentTime;
        }
    }

    function getAmountTokenLastDay() public view returns (uint256 amountTokenLastDay) {
        uint256 currentDay = getCurrentDate();
        uint256 numberCurrentDay = getNumberDay(currentDay);
        amountTokenLastDay = paidPerDay[numberCurrentDay];
    }

    function getAmountTokenLastDayIfLessTen() public view returns (uint256 amountTokenLastDayIfLessTen) {
        uint256 currentDay = getCurrentDate();
        uint256 numberCurrentDay = getNumberDay(currentDay);
        amountTokenLastDayIfLessTen = paidPerDay[numberCurrentDay];
        if (amountTokenLastDayIfLessTen > 10) {
            amountTokenLastDayIfLessTen = 0;
        }
    }

    function ethTransferLastInvestors(uint256 _value) internal returns(uint256 profit) {
        require(arrayPaidTokenLastDay.length > 0);
        uint256 valueLastInvestor = _value.mul(percentToLastToken).div(100);
        address currInvestor = address(0);
        uint lastNumberInvestor = arrayPaidTokenLastDay.length;
        uint256 amountToken = 0;
        profit = 0;
        uint256 count = getCountInvestLastToken();
        uint256 valueLastTenInvestor = _value.mul(percentToLastRemainingToken).div(count.mul(100));

        if (address(this).balance > valueLastTenInvestor.mul(10).add(valueLastInvestor)){
            uint step = 0;
            while (step < amountLastToken.add(1)) {
                if (lastNumberInvestor > 0) {
                    currInvestor = arrayPaidTokenLastDay[lastNumberInvestor-1].investor;
                    amountToken = amountToken.add(arrayPaidTokenLastDay[lastNumberInvestor-1].amountToken);
                    if (step == 0) {
                        currInvestor.transfer(valueLastInvestor.add(valueLastTenInvestor));
                        totalPrize = totalPrize.add(valueLastInvestor.add(valueLastTenInvestor));
                        profit = profit.add(valueLastInvestor.add(valueLastTenInvestor));
                        if (amountToken >= amountLastToken) {
                            step = amountLastToken.add(1);
                        }
                    } else {
                        currInvestor.transfer(valueLastTenInvestor);
                        totalPrize = totalPrize.add(valueLastTenInvestor);
                        profit = profit.add(valueLastTenInvestor);
                        if (amountToken >= amountLastToken) {
                            step = amountLastToken.add(1);
                        }
                    }
                    step++;
                    lastNumberInvestor--;
                } else {
                    step = amountLastToken.add(1);
                }
            }
        }
    }

    function getCountInvestLastToken() internal view returns (uint256 count) {
        uint256 lastNumberInvestor = arrayPaidTokenLastDay.length;
        uint256 step = 0;
        uint256 amountToken = 0;
        count = 0;
        while (step < amountLastToken.add(1)) {
            if (lastNumberInvestor > 0) {
                amountToken = amountToken.add(arrayPaidTokenLastDay[lastNumberInvestor-1].amountToken);
                if (step == 0) {
                    count++;
                    if (amountToken >= amountLastToken) {
                        step = amountLastToken.add(1);
                    }
                } else {
                    count++;
                    if (amountToken >= amountLastToken) {
                        step = amountLastToken.add(1);
                    }
                }
                step++;
                lastNumberInvestor--;
            } else {
                step = amountLastToken.add(1);
            }
        }
    }

    function getCurrentDate() public view returns (uint256) {
        if (isDemo) {
            return simulateDate;
        }
        return now;
    }

    function getNumberDay(uint256 _date) public pure returns (uint256 result) {
        result = _date.div(1 days);
    }

    function getPaidPerDay(uint256 _numberDay) public view returns (uint256 result) {
        result = paidPerDay[_numberDay];
    }

    function setSimulateDate(uint256 _newDate) public onlyOwner {
        if (isDemo) {
            require(_newDate > simulateDate);
            emit ChangeTime(_newDate, simulateDate);
            simulateDate = _newDate;
        } else {
            require(_newDate == 0);
            simulateDate = 0;
            emit ChangeTime(_newDate, simulateDate);
        }
    }

    function setStartDate(uint256 _newDate) public onlyOwner {
        require(_newDate >= 0);
        startTime = _newDate;
    }
}

/**
 * @title PeriodsStorage
 */
contract HouseStorage is Ownable, InvestorStorage {
    using SafeMath for uint256;
    // address where funds are collected

    uint256 public averagePriceToken = 0;

    uint256 public totalEthRaised = 0;
    uint256 public totalTokenRaised = 0;
    uint256 public tokenAllocated = 0;
    uint256 public totalFloorBuilded = 0;
    uint256 public totalRefundEth = 0;

    uint256 MAX_NUMBER_HOUSE = 1000;

    uint256 public numberTokensPerFloor = 300; //for test's
    uint256 public maxNumberFloorPerHouse = 3; //for test's
    uint256 public minNumberSalesTokens = 10;
    uint256 public tokensCostIncreaseRatio = 105;
    uint256 public percentToAdministration = 18;
    uint256 public maxBuyTokenToAdministration = 1000;

    address public administrationWallet;

    bool public finishProject;
    bool firstDay = false;

    uint256 public currentHouse;

    struct House {
        uint256 lastFloor;
        uint256 paymentTokenPerFloor;
        uint256 paymentTokenTotal;
        uint256 totalEth;
        uint256 priceToken;
        uint256 refundToken;
        uint256 refundEth;
        uint256 startTimeBuild;
        uint256 stopTimeBuild;
    }

    mapping (uint256 => House) private houses;

    event NextFloor(uint256 date, uint256 numberFloor);
    event TokenSale(address indexed investor, uint256 date, uint256 priceToken, uint256 amountEth, uint256 amountToken);
    event StopBuyTokens(uint256 date);

    constructor() public {
        stopBuyTokens = false;
        finishProject = false;
//        startTime = now; //for test's
        startTime = 0; //for test's
        simulateDate = startTime;
    }

    function initHouse(uint256 _numberHouse, uint256 _priceToken) internal {
        House storage house = houses[_numberHouse];
        house.priceToken = _priceToken;
        uint256 currentDay = getCurrentDate();
        if (_numberHouse == 1) {
            house.startTimeBuild = currentDay;
        } else {
            uint256 numberCheckDay = getNumberDay(currentDay);
            house.startTimeBuild = numberCheckDay.add(1).mul(1 days).add(60);
        }
        house.paymentTokenPerFloor = tokenAllocated;
        house.paymentTokenTotal = tokenAllocated;
        firstDay = true;
        totalEthPerHouse = 0;
    }

    function houseInfo(uint256 _numberHouse) public view returns (
        uint256 paymentTokenPerFloor, uint256 paymentTokenTotal,
        uint256 priceToken, uint256 lastFloor, uint256 totalEth,
        uint256 refundEth
    ) {
        paymentTokenPerFloor = houses[_numberHouse].paymentTokenPerFloor;
        paymentTokenTotal = houses[_numberHouse].paymentTokenTotal;
        priceToken = houses[_numberHouse].priceToken;
        lastFloor = houses[_numberHouse].lastFloor;
        totalEth = houses[_numberHouse].totalEth;
        refundEth = houses[_numberHouse].refundEth;
    }

    function houseTimeInfo(uint256 _numberHouse) public view returns (
        uint256 startTimeBuild, uint256 stopTimeBuild
    ) {
        startTimeBuild = houses[_numberHouse].startTimeBuild;
        stopTimeBuild = houses[_numberHouse].stopTimeBuild;
    }

    function checkStopBuyTokens(uint256 _date) public returns(bool) { //for test's
        //function checkStopBuyTokens(uint256 _date) internal returns(bool) {
        uint256 timeLastPayment = startTime;
        uint256 countPaidTokenPrevDay = 0;
        uint lastNumberInvestor = 0;
        if (arrayPaidTokenLastDay.length > 0) {
            lastNumberInvestor = arrayPaidTokenLastDay.length-1;
            timeLastPayment = arrayPaidTokenLastDay[lastNumberInvestor].paymentTime;
        }
        uint256 numberCheckDay = getNumberDay(_date);
        uint256 numberStartBuildHouse = getNumberDay(houses[currentHouse].startTimeBuild);
        countPaidTokenPrevDay = paidPerDay[numberCheckDay-1];

        if (stopBuyTokens == false) {
            if (countPaidTokenPrevDay > 0) {
                firstDay = false;
            }
            if (numberStartBuildHouse.add(2) < numberCheckDay) {
                firstDay = false;
            }
            if (!firstDay) {
                if (countPaidTokenPrevDay < minNumberSalesTokens) {
                    makeStopBuyTokens();
                }
            }
        } else {
            if (currentHouse > 1 && numberStartBuildHouse < numberCheckDay && !finishProject) {
                stopBuyTokens = toSecondFloorNewHouse();
            }
        }
        return stopBuyTokens;
    }

    function toSecondFloorNewHouse() internal returns (bool) {
        houses[currentHouse].paymentTokenTotal = tokenAllocated;
        numberTokensPerFloor = tokenAllocated;
        houses[currentHouse].paymentTokenPerFloor = 0;
        if (tokenAllocated == 0) {
            houses[currentHouse].totalEth = 0;
            houses[currentHouse].priceToken = 0;
            finishProject = true;
            return true;
        } else {
            totalFloorBuilded = totalFloorBuilded.add(1);
            houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
            houses[currentHouse].totalEth = address(this).balance;
            houses[currentHouse].priceToken = averagePriceToken.mul(tokensCostIncreaseRatio).div(100);
            return false;
        }
    }

    function makeStopBuyTokens() internal {
        stopBuyTokens = true;
        closeBuyTokens();
    }

    function closeBuyTokens() internal returns(bool) {
        uint256 currentRaisedEth = getTotalEthPerHouse(currentHouse);
        uint256 currentRaisedToken = getTotalTokenPerHouse(currentHouse);
        uint256 fullPercent = 100;

        uint256 amountToAdministration = currentRaisedEth.mul(percentToAdministration).div(fullPercent);
        uint256 totalPercent = percentToAdministration.add(percentToLastRemainingToken).add(percentToLastToken);
        uint256 transferEth = currentRaisedEth.mul(totalPercent).div(fullPercent);
        uint256 percentToInvestor = fullPercent.sub(totalPercent);
        uint256 profit = 0;
        averagePriceToken = currentRaisedEth.mul(percentToInvestor).div(fullPercent).div(currentRaisedToken);
        //averagePriceToken = roundPrice(averagePriceToken, 3); //for test's
        houses[currentHouse].stopTimeBuild = getCurrentDate();
        totalFloorBuilded = totalFloorBuilded.add(1);

        currentHouse++;
        if (currentHouse < MAX_NUMBER_HOUSE) {
            initHouse(currentHouse, averagePriceToken);
        } else {
            finishProject = true;
        }

        if (address(this).balance > transferEth){
            administrationWallet.transfer(amountToAdministration);
            profit = ethTransferLastInvestors(currentRaisedEth);
            houses[currentHouse-1].refundEth = houses[currentHouse-1].refundEth.add(amountToAdministration).add(profit);
            return true;
        }
        emit StopBuyTokens(getCurrentDate());
        return false;
    }

    function checkBuyTokenPerFloor(uint256 _amountEth) public view returns(uint256 tokens, uint256 needEth) {
        require(_amountEth > 0);
        uint256 amountFreeToken = getFreeTokenPerFloor(currentHouse);
        uint256 buyToken = _amountEth.div(houses[currentHouse].priceToken);

        if (buyToken <= amountFreeToken) {
            tokens = buyToken;
            needEth = _amountEth;
        } else {
            tokens = amountFreeToken;
            needEth = houses[currentHouse].priceToken.mul(amountFreeToken);
        }
    }

    function getFreeTokenPerFloor(uint256 _numberHouse) public view returns(uint256 tokens) {
        return numberTokensPerFloor.sub(houses[_numberHouse].paymentTokenPerFloor);
    }

    function getFreeTokenNextFloor() public view returns(uint256 tokens) {
        bool lastFloor = houses[currentHouse].lastFloor.add(1) >= maxNumberFloorPerHouse;
        return lastFloor ? 0 : numberTokensPerFloor;
    }

    function getTotalEthPerHouse(uint256 _numberHouse) public view returns(uint256 eths) {
        return houses[_numberHouse].totalEth;
    }

    function getTotalTokenPerHouse(uint256 _numberHouse) public view returns(uint256 tokens) {
        return houses[_numberHouse].paymentTokenTotal;
    }

    function getBuyToken(uint256 _amountEth) public returns(uint256 totalTokens, uint256 remainEth, bool lastFloorPerHouse) { // for test's
        //function getBuyToken(uint256 _amountEth) internal returns(uint256 totalTokens, uint256 remainEth, bool lastFloorPerHouse) {
        lastFloorPerHouse = false;
        bool lastFloor = houses[currentHouse].lastFloor.add(1) >= maxNumberFloorPerHouse;
        uint256 priceToken = houses[currentHouse].priceToken;
        require(0 < _amountEth && _amountEth >= priceToken);
        uint256 diffEth = 0;
        uint256 eths = 0;
        uint256 tokens = 0;
        (tokens, eths) = checkBuyTokenPerFloor(_amountEth);
        totalTokens = totalTokens.add(tokens);

        diffEth = getDifferentEth(tokens, eths, priceToken);
        eths = eths.sub(diffEth);
        uint256 freeEth = _amountEth.sub(eths);
        uint256 addBuyToken = 0;
        if (tokens > 0) {
            writePurchaise(eths, tokens);
            if (freeEth < priceToken) {
                remainEth = freeEth;
                freeEth = 0;
            }
        } else {
            if (lastFloor) {
                remainEth = _amountEth;
                lastFloorPerHouse = true;
                freeEth = 0;
                stopBuyTokens = true;
                closeBuyTokens();
            } else {
                lastFloor = houses[currentHouse].lastFloor.add(1) >= maxNumberFloorPerHouse;
                if (lastFloor) {
                    lastFloorPerHouse = true;
                }
                freeEth = _amountEth;
                totalTokens = 0;
            }
        }

        while (freeEth > 0) {
            if (nextFloor()) {
                priceToken = houses[currentHouse].priceToken;
                addBuyToken = freeEth.div(priceToken);
                if (addBuyToken > numberTokensPerFloor) {
                    totalTokens = totalTokens.add(numberTokensPerFloor);

                    writePurchaise(numberTokensPerFloor.mul(priceToken), numberTokensPerFloor);
                    freeEth = freeEth.sub(numberTokensPerFloor.mul(priceToken));
                } else {
                    diffEth = getDifferentEth(addBuyToken, freeEth, priceToken);
                    eths = freeEth.sub(diffEth);
                    remainEth = diffEth;
                    freeEth = 0;
                    totalTokens = totalTokens.add(addBuyToken);
                    writePurchaise(eths, addBuyToken);
                }
            } else {
                remainEth = freeEth;
                freeEth = 0;
            }
        }
    }

    function getBuyTokenAdmin(uint256 _amountEth) public returns(uint256 totalTokens, uint256 remainEth) { // for test's
//    function getBuyTokenAdmin(uint256 _amountEth) internal returns(uint256 totalTokens, uint256 remainEth) { // for test's
        require(_amountEth > 0);
        totalTokens = _amountEth.div(averagePriceToken);
        if (maxBuyTokenToAdministration.add(1) > totalTokens) {
            uint256 diffEth = getDifferentEth(totalTokens, _amountEth, averagePriceToken);
            remainEth = diffEth;
            writePurchaise(_amountEth.sub(diffEth), totalTokens);
        } else {
            totalTokens = 0;
            remainEth = _amountEth;
        }
    }

    function getDifferentEth(uint256 _amountToken, uint256 _amountEth, uint256 _priceToken) public pure returns(uint256 result) {  //for test's
        //function getDifferentEth(uint256 _amountToken, uint256 _amountEth, uint256 _priceToken) internal pure returns(uint256 result) {
        uint256 realEth = _amountToken.mul(_priceToken);
        if (realEth <= _amountEth) {
            result = _amountEth.sub(realEth);
        } else {
            result = 0;
        }
    }

    function getSaleToken(address _investor, uint256 _date) internal returns(bool result) {
        require(_investor != address(0));
        result = false;
        uint256 numberCheckDay = getNumberDay(getCurrentDate());
        uint256 countPaidTokenPrevDay = paidPerDay[numberCheckDay];

        require(stopBuyTokens && countPaidTokenPrevDay == 0);
        saleToken(_investor, _date);
        result = true;
    }

    function getPriceTokenNextHouse() public view returns(uint256 result) {
        uint256 fullPercent = 100;

        uint256 totalPercent = percentToAdministration.add(percentToLastRemainingToken).add(percentToLastToken);
        uint256 percentToInvestor = fullPercent.sub(totalPercent);

        uint256 amountEth = getTotalEthPerHouse(currentHouse).mul(percentToInvestor).div(fullPercent);
        result = amountEth.div(houses[currentHouse].priceToken);
    }

    function saleToken(address _investor, uint256 _date) internal {
        require(_investor != address(0));
        require(currentHouse > 0);
        Investor storage inv = investors[_investor];
        uint256 refundEth = inv.amountToken.mul(averagePriceToken);
        uint256 prevHouse = currentHouse.sub(1);
        uint256 currentDay = getCurrentDate();
        uint256 numberCurrentDay = getNumberDay(currentDay);
        if (paidPerDay[numberCurrentDay-1] > 0) {
            delete arrayPaidTokenLastDay;
        }

        if (address(this).balance > refundEth){ // for test's
            houses[prevHouse].refundToken =  houses[prevHouse].refundToken.add(inv.amountToken);
            houses[prevHouse].refundEth =  houses[prevHouse].refundEth.add(refundEth);
            houses[currentHouse].paymentTokenPerFloor = houses[currentHouse].paymentTokenPerFloor.sub(inv.amountToken);
            houses[currentHouse].paymentTokenTotal = houses[currentHouse].paymentTokenTotal.sub(inv.amountToken);
            tokenAllocated = tokenAllocated.sub(inv.amountToken);
            inv.refundEth = inv.refundEth.add(refundEth);
            emit TokenSale(_investor, _date, averagePriceToken, refundEth, inv.amountToken);
            inv.amountToken = 0;
            inv.sellTime = _date;
            totalRefundEth = totalRefundEth.add(refundEth);

            _investor.transfer(refundEth); // for test's
        } // for test's
    }

    function writePurchaise(uint256 _amountEth, uint256 _amountToken) internal {
        require(_amountEth >= 0);
        require(_amountToken >= 0);

        houses[currentHouse].totalEth = houses[currentHouse].totalEth.add(_amountEth);
        houses[currentHouse].paymentTokenPerFloor = houses[currentHouse].paymentTokenPerFloor.add(_amountToken);
        houses[currentHouse].paymentTokenTotal = houses[currentHouse].paymentTokenTotal.add(_amountToken);
    }

    function nextFloor() internal returns (bool result){
        if (houses[currentHouse].lastFloor.add(1) < maxNumberFloorPerHouse) {
            houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
            houses[currentHouse].paymentTokenPerFloor = 0;
            houses[currentHouse].priceToken = houses[currentHouse].priceToken.mul(tokensCostIncreaseRatio).div(100);
            totalFloorBuilded = totalFloorBuilded.add(1);
            emit NextFloor(getCurrentDate(), houses[currentHouse].lastFloor);
            result = true;
        } else {
            result = false;
        }
    }

    function roundPrice(uint256 numerator, uint256 precision) internal pure returns(uint256 round) {
        if (precision > 0 && precision < 18) {
            uint256 _numerator = numerator / 10 ** (18 - precision - 1);
            _numerator = (_numerator + 5) / 10;
            round = (_numerator) * 10 ** (18 - precision);
        }
    }

    function setDemo() public onlyOwner {
        if (currentHouse == 1) {
            isDemo = true;
        }
    }
}

contract DreamCity is Ownable, HouseStorage {
    using SafeMath for uint256;

    uint256 FIRST_PRICE_TOKEN = 0.05 ether;
    uint256 ETH_FOR_SALE_TOKEN = 0.0001 ether;


    event TotalTokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event CurrentPeriod(uint period);
    event RefundEth(address indexed investor, uint256 value);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);


    constructor(address _owner, address _ownerTwo, address _administrationWallet) public
    {
        require(_owner != address(0));
        require(_ownerTwo != address(0));
        require(_administrationWallet != address(0));
        owner = _owner;
        ownerTwo = _ownerTwo;
        administrationWallet = _administrationWallet;
        owner = msg.sender; // for test's
        averagePriceToken = FIRST_PRICE_TOKEN;
        currentHouse = 1;
        addToAdminlist(administrationWallet);
        initHouse(1, FIRST_PRICE_TOKEN);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        if (msg.value >= averagePriceToken) {
            buyTokens(msg.sender);
        } else if (msg.value == ETH_FOR_SALE_TOKEN) {
            saleTokens(msg.sender);
        } else {
            refundEth(msg.sender, msg.value);
        }
    }

    function refundEth(address _investor, uint256 _value) internal returns (bool) {
        require(_investor != address(0));
        _investor.transfer(_value);
        emit RefundEth(_investor, _value);
    }

    function buyTokens(address _investor) public payable returns (uint256 tokens){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        tokens = 0;
        uint256 remainEth = 0;
        bool lastFloorPerHouse = false;

        uint256 currentDate = getCurrentDate();
        if (checkStopBuyTokens(currentDate) == false) {
            (tokens, remainEth, lastFloorPerHouse) = getBuyToken(weiAmount);
            if (tokens == 0) {
                refundEth(_investor, remainEth); // for test's
                return 0;
            }

            totalEthRaised = totalEthRaised.add(weiAmount).sub(remainEth);
            totalTokenRaised = totalTokenRaised.add(tokens);
            tokenAllocated = tokenAllocated.add(tokens);

            if (checkNewInvestor(_investor)) {
                newInvestor(_investor, weiAmount.sub(remainEth), tokens, currentDate, currentHouse);
            } else {
                addFundToInvestor(_investor, weiAmount.sub(remainEth), tokens, currentDate, currentHouse);
            }
            emit TotalTokenPurchase(_investor, weiAmount.sub(remainEth), tokens);
            refundEth(_investor, remainEth); // for test's
        } else {
            if (msg.value == ETH_FOR_SALE_TOKEN) {
                saleTokens(_investor);
                return 0;
            }

            if (admins[_investor]) {
                (tokens, remainEth) = getBuyTokenAdmin(weiAmount);
                totalEthRaised = totalEthRaised.add(weiAmount).sub(remainEth);
                totalTokenRaised = totalTokenRaised.add(tokens);
                tokenAllocated = tokenAllocated.add(tokens);
                addFundToInvestor(_investor, weiAmount.sub(remainEth), tokens, currentDate, currentHouse);
                return 0;
            }
            refundEth(_investor, weiAmount); // for test's
        }
    }

function claimEth() public onlyOwner {
    require(finishProject);
    uint256 amountEth = address(this).balance;
    if (amountEth > 0){
        administrationWallet.transfer(amountEth);
    }
}

function saleTokens(address _investor) public payable {
        require(_investor != address(0));
        require(msg.value == ETH_FOR_SALE_TOKEN);
        uint256 currentDate = getCurrentDate();
        require(getSaleToken(_investor, currentDate));
    }

    function addToAdminlist(address _admin) public onlyOwner {
        admins[_admin] = true;
    }

    function removeFromAdminlist(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    function setNumberTokensPerFloor(uint256 _number) external onlyOwner {
        require(_number > 0);
        numberTokensPerFloor = _number;
    }

    function setMaxBuyTokenToAdministration(uint256 _amount) external onlyOwner {
        require(_amount > 0);
        maxBuyTokenToAdministration = _amount;
    }

    function setTokensCostIncreaseRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0);
        tokensCostIncreaseRatio = _ratio;
    }

    function setPercentToAdministration(uint256 _percent) external onlyOwner {
        require(_percent > 0);
        percentToAdministration = _percent;
    }

    function setPercentToLastToken(uint256 _percent) external onlyOwner {
        require(_percent > 0);
        percentToLastToken = _percent;
    }

    function setPercentToLastRemainingToken(uint256 _percent) external onlyOwner {
        require(_percent > 0);
        percentToLastRemainingToken = _percent;
    }

    function setMinNumberSalesTokens(uint256 _number) external onlyOwner {
        require(_number > 0);
        minNumberSalesTokens = _number;
    }

    function setMaxNumberFloorPerHouse(uint256 _number) external onlyOwner {
        require(_number > 0);
        maxNumberFloorPerHouse = _number;
    }

    function setAdministrationWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = administrationWallet;
        administrationWallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }
}
