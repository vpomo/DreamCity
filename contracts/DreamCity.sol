pragma solidity ^0.4.25;


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

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
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

}

/**
 * @title InvestorStorage
 */
contract InvestorStorage is Ownable {
    using SafeMath for uint256;

    uint256 public countInvestors;
    uint256 NUMBER_LAST_TOKEN = 10;
    uint256 PERCENT_TO_LAST_TEN_TOKEN = 1;
    uint256 PERCENT_TO_LAST_TOKEN = 1;
    uint256 public totalPrize = 0;

    bool public isDemo;

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
        paidPerDay[numberDay] = paidPerDay[numberDay].add(_amountToken);
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

    function ethTransferLastInvestors(uint256 _value) internal returns(bool) {
        require(arrayPaidTokenLastDay.length > 0);
        uint256 valueLastTenInvestor = _value.mul(PERCENT_TO_LAST_TEN_TOKEN).div(1000);
        uint256 valueLastInvestor = _value.mul(PERCENT_TO_LAST_TOKEN).div(100);
        address currInvestor = address(0);
        uint lastNumberInvestor = arrayPaidTokenLastDay.length;
        uint256 amountToken = 0;

        if (address(this).balance > valueLastTenInvestor.mul(10).add(valueLastInvestor)){
            uint step = 0;
            while (step < NUMBER_LAST_TOKEN.add(1)) {
                if (lastNumberInvestor > 0) {
                    currInvestor = arrayPaidTokenLastDay[lastNumberInvestor-1].investor;
                    amountToken = amountToken.add(arrayPaidTokenLastDay[lastNumberInvestor-1].amountToken);
                    if (step == 0) {
                        if (amountToken < NUMBER_LAST_TOKEN) {
                            currInvestor.transfer(valueLastInvestor.add(valueLastTenInvestor));
                            totalPrize = totalPrize.add(valueLastInvestor.add(valueLastTenInvestor));
                        } else {
                            step = NUMBER_LAST_TOKEN;
                        }
                    } else {
                        if (amountToken > NUMBER_LAST_TOKEN) {
                            step = NUMBER_LAST_TOKEN;
                        } else {
                            currInvestor.transfer(valueLastTenInvestor);
                            totalPrize = totalPrize.add(valueLastTenInvestor);
                        }
                    }
                    step++;
                    lastNumberInvestor--;
                } else {
                    step = NUMBER_LAST_TOKEN.add(1);
                }
            }
            return true;
        } else {
            return false;
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

    function setDemo(bool _status) public onlyOwner {
        isDemo = _status;
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

    //    uint256 numberTokensPerFloor = 1000; // for test's
    uint256 public numberTokensPerFloor = 300; //for test's
    //    uint256 MAX_NUMBER_FLOOR_PER_HOUSE = 1000; // for test's
    uint256 MAX_NUMBER_FLOOR_PER_HOUSE = 3; //for test's
    uint256 MAX_NUMBER_HOUSE = 1000;
    uint256 MIN_NUMBER_SALES_TOKENS = 10;
    uint256 TOKENS_COST_INCREASE_RATIO = 105;
    uint256 PERCENT_TO_ADMINISTRATION = 8;
    uint256 PERCENT_TO_WALLET = 10;

    address public administrationWallet;
    address public wallet;

    bool public stopBuyTokens;
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
        startTime = 0;
        simulateDate = 0;
    }

    function initHouse(uint256 _numberHouse, uint256 _priceToken) internal {
        House storage house = houses[_numberHouse];
        house.priceToken = _priceToken;
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
        countPaidTokenPrevDay = paidPerDay[numberCheckDay-1];

        if (countPaidTokenPrevDay > 0) {
            firstDay = false;
        }

        if (stopBuyTokens == false) {
            if (!firstDay) {
                if (countPaidTokenPrevDay < MIN_NUMBER_SALES_TOKENS || houses[currentHouse].lastFloor.add(1) >= MAX_NUMBER_FLOOR_PER_HOUSE) {
                    makeStopBuyTokens(_date);
                }
            } else {
                if (paidPerDay[numberCheckDay] == numberTokensPerFloor.mul(MAX_NUMBER_FLOOR_PER_HOUSE)) {
                    makeStopBuyTokens(_date);
                }
            }
        } else {
            uint256 numberStartBuildHouse = getNumberDay(houses[currentHouse].startTimeBuild);
            if (numberCheckDay.sub(numberStartBuildHouse) == 2) {
                stopBuyTokens = false;
                toSecondFloorNewHouse();
            }
        }
        return stopBuyTokens;
    }

    function toSecondFloorNewHouse() internal {
        totalFloorBuilded = totalFloorBuilded.add(1);
        houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
        houses[currentHouse].paymentTokenTotal = tokenAllocated;
        numberTokensPerFloor = tokenAllocated;
        houses[currentHouse].paymentTokenPerFloor = 0;
        houses[currentHouse].priceToken = averagePriceToken.mul(TOKENS_COST_INCREASE_RATIO).div(100);
    }

    function makeStopBuyTokens(uint256 _date) internal {
        stopBuyTokens = true;
        closeBuyTokens();
        emit StopBuyTokens(_date);
    }

    function isOneDay(uint256 _date) public view returns(bool result) {
        uint256 currentData = getCurrentDate();
        uint256 currentNumberDays = currentData.div(1 days);
        uint256 checkNumberDays = _date.div(1 days);
        if (currentNumberDays > checkNumberDays) {
            result = false;
        } else {
            result = true;
        }
    }

    function closeBuyTokens() internal returns(bool) {
        uint256 currentRaisedEth = getTotalEthPerHouse(currentHouse);
        uint256 currentRaisedToken = getTotalTokenPerHouse(currentHouse);

        uint256 amountToAdministration = currentRaisedEth.mul(PERCENT_TO_ADMINISTRATION).div(100);
        uint256 totalPercent = PERCENT_TO_ADMINISTRATION.add(PERCENT_TO_LAST_TEN_TOKEN).add(PERCENT_TO_LAST_TOKEN);
        uint256 transferEth = currentRaisedEth.mul(totalPercent).div(100);
        averagePriceToken = currentRaisedEth.mul(80).div(100).div(currentRaisedToken);
        houses[currentHouse].stopTimeBuild = getCurrentDate();
        totalFloorBuilded = totalFloorBuilded.add(1);

        currentHouse++;
        if (currentHouse < MAX_NUMBER_HOUSE) {
            initHouse(currentHouse, averagePriceToken);
        }

        if (address(this).balance > transferEth){
            administrationWallet.transfer(amountToAdministration);
            ethTransferLastInvestors(currentRaisedEth);
            return true;
        }
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
        bool lastFloor = houses[currentHouse].lastFloor.add(1) >= MAX_NUMBER_FLOOR_PER_HOUSE;
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
        require(_amountEth > 0);
        uint256 diffEth = 0;
        uint256 eths = 0;
        uint256 tokens = 0;
        uint256 priceToken = houses[currentHouse].priceToken;
        (tokens, eths) = checkBuyTokenPerFloor(_amountEth);
        totalTokens = totalTokens.add(tokens);

        diffEth = getDifferentEth(tokens, eths, priceToken);
        eths = eths.sub(diffEth);
        uint256 freeEth = _amountEth.sub(eths);
        uint256 addBuyToken = 0;
        bool lastFloor = houses[currentHouse].lastFloor.add(1) >= MAX_NUMBER_FLOOR_PER_HOUSE;
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
        require(_amountEth > 0);
        totalTokens = _amountEth.div(averagePriceToken);
        uint256 diffEth = getDifferentEth(totalTokens, _amountEth, averagePriceToken);
        remainEth = diffEth;
        writePurchaise(_amountEth.sub(diffEth), totalTokens);
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
        require(stopBuyTokens);
        saleToken(_investor, _date);
        result = true;
    }

    function getPriceTokenNextHouse() public view returns(uint256 result) {
        uint256 amountEth = getTotalEthPerHouse(currentHouse).mul(8).div(10);
        result = amountEth.div(houses[currentHouse].priceToken);
    }

    function saleToken(address _investor, uint256 _date) internal {
        require(_investor != address(0));
        require(currentHouse > 0);
        Investor storage inv = investors[_investor];
        uint256 refundEth = inv.amountToken.mul(averagePriceToken);
        uint256 amountWallet = 0;
        uint256 prevHouse = currentHouse.sub(1);
        uint256 currentDay = getCurrentDate();
        uint256 numberCurrentDay = getNumberDay(currentDay);
        if (paidPerDay[numberCurrentDay-1] > 0) {
            delete arrayPaidTokenLastDay;
        }

        if (address(this).balance > refundEth){ // for test's
            amountWallet = refundEth.mul(PERCENT_TO_WALLET).div(100);
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

            wallet.transfer(amountWallet); // for test's
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
        if (houses[currentHouse].lastFloor.add(1) < MAX_NUMBER_FLOOR_PER_HOUSE) {
            houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
            houses[currentHouse].paymentTokenPerFloor = 0;
            houses[currentHouse].priceToken = houses[currentHouse].priceToken.mul(TOKENS_COST_INCREASE_RATIO).div(100);
            totalFloorBuilded = totalFloorBuilded.add(1);
            emit NextFloor(getCurrentDate(), houses[currentHouse].lastFloor);
            result = true;
        } else {
            result = false;
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


    constructor(address _owner, address _administrationWallet, address _wallet) public
    {
        require(_owner != address(0));
        require(_administrationWallet != address(0));
        require(_wallet != address(0));
        owner = _owner;
        administrationWallet = _administrationWallet;
        wallet = _wallet;
        owner = msg.sender; // for test's
        averagePriceToken = FIRST_PRICE_TOKEN;
        currentHouse = 1;
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
            }
            refundEth(_investor, weiAmount); // for test's
        }
    }

    function saleTokens(address _investor) public payable {
        require(_investor != address(0));
        require(msg.value == ETH_FOR_SALE_TOKEN);
        uint256 currentDate = getCurrentDate();
        require(getSaleToken(_investor, currentDate));
    }

    function addToAdminlist(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeFromAdminlist(address _admin) external onlyOwner {
        admins[_admin] = false;
    }
}
