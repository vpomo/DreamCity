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
    function changeOwner(address _newOwner) onlyOwner internal {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

/**
 * @title InvestorStorage
 * @dev InvestorStorage is a base contract for ***
 */
contract InvestorStorage is Ownable {
    using SafeMath for uint256;
    // address where funds are collected

    uint256 public countInvestors;
    uint256 NUMBER_LAST_INVESTORS = 11;
    uint256 public PERCENT_TO_LAST_TEN_INVESTOR = 1;
    uint256 public PERCENT_TO_LAST_INVESTOR = 1;


    address[] arrayLastInvestors;

    struct Investor {
        uint256 investmentEth;
        uint256 refundEth;
        uint256 amountToken;
        uint256 paymentTime;
        uint256 sellTime;
        uint256 numberHouse;
    }

    mapping (address => Investor) public investors;

    constructor() public {
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

    function newInvestor(address _investor, uint256 _investment, uint256 _amountToken, uint256 _paymentTime) public returns (bool) {
        if (!checkNewInvestor(_investor)) {
            return false;
        }
        addFundToInvestor(_investor, _investment, _amountToken, _paymentTime);
        countInvestors++;
        return true;
    }

    function checkNewInvestor(address _investor) public view returns (bool) {
        Investor storage inv = investors[_investor];
        if (inv.paymentTime > 0 && inv.investmentEth > 0) {
            return false;
        }
        return true;
    }

    function addFundToInvestor(address _investor, uint256 _investment, uint256 _amountToken, uint256 _paymentTime) public {
        Investor storage inv = investors[_investor];
        inv.investmentEth = inv.investmentEth.add(_investment);
        inv.amountToken = inv.amountToken.add(_amountToken);
        inv.paymentTime = _paymentTime;
        setLastInvestor(_investor);
    }

    function setLastInvestor(address _investor) public {
        require(_investor != address(0));
        if (arrayLastInvestors.length > NUMBER_LAST_INVESTORS) {
            arrayLastInvestors = removeElemLastAddressInvestors(0);
        }
        arrayLastInvestors.push(_investor);
    }

    function removeElemLastAddressInvestors(uint index) internal returns(address[]) {
        if (index >= arrayLastInvestors.length) return;

        for (uint i = index; i<arrayLastInvestors.length-1; i++){
            arrayLastInvestors[i] = arrayLastInvestors[i+1];
        }
        delete arrayLastInvestors[arrayLastInvestors.length-1];
        arrayLastInvestors.length--;
        return arrayLastInvestors;
    }

    function ethTransferLastInvestors(uint256 _value) internal returns(bool) {
        uint256 valueLastTenInvestor = _value.mul(PERCENT_TO_LAST_TEN_INVESTOR).div(1000);
        uint256 valueLastInvestor = _value.mul(PERCENT_TO_LAST_INVESTOR).div(100);
        if (address(this).balance > valueLastTenInvestor.mul(10) + valueLastInvestor){
            for (uint i = 0; i<arrayLastInvestors.length-1; i++){
                arrayLastInvestors[i].transfer(valueLastTenInvestor);
                if (i == arrayLastInvestors.length-1) {
                    arrayLastInvestors[i].transfer(valueLastInvestor);
                }
            }
            return true;
        } else {
            return false;
        }
    }
}

/**
 * @title PeriodsStorage
 * @dev PeriodsStorage is a base contract for ***
 */
contract HouseStorage is Ownable, InvestorStorage {
    using SafeMath for uint256;
    // address where funds are collected

    uint256 public averagePriceToken = 0;
    uint256 public currentPriceToken;

    uint256 public NUMBER_TOKENS_PER_FLOOR = 1000;
    uint256 public MAX_NUMBER_FLOOR_PER_HOUSE = 1000;
    uint256 public MIN_NUMBER_SALES_TOKENS = 6;
    uint256 public TOKENS_COST_INCREASE_RATIO = 105;
    uint256 public PERCENT_TO_ADMINISTRATION = 8;
    uint256 public PERCENT_TO_WALLET = 10;

    address public administrationWallet;
    address public wallet;

    bool public stopBuyTokens = false;

    uint256 public currentHouse;

    struct House {
        uint256 lastFloor;
        uint256 paymentTokenPerFloor;
        uint256 paymentTokenTotal;
        uint256 totalEth;
        uint256 priceToken;
        uint256 refundToken;
    }

    uint256[] arrayLastPayment;

    mapping (uint256 => House) private houses;

    constructor() public {
    }

    function initHouse(uint256 _numberHouse, uint256 _priceToken) public {
        House storage house = houses[_numberHouse];
        house.priceToken = _priceToken;
    }

    function houseInfo(uint256 _numberHouse) public view returns (
        uint256 paymentTokenPerFloor, uint256 paymentTokenTotal,
        uint256 priceToken
    ) {
        paymentTokenPerFloor = houses[_numberHouse].paymentTokenPerFloor;
        paymentTokenTotal = houses[_numberHouse].paymentTokenTotal;
        priceToken = houses[_numberHouse].priceToken;
    }

    function setTimePayment(uint256 _date) public {
        require(_date > 0);
        if (arrayLastPayment.length > MIN_NUMBER_SALES_TOKENS) {
            arrayLastPayment = removeElemLastTimePayment(0);
        }
        arrayLastPayment.push(_date);
    }

    function removeElemLastTimePayment(uint index) internal returns(uint[]) {
        if (index >= arrayLastPayment.length) return;

        for (uint i = index; i<arrayLastPayment.length-1; i++){
            arrayLastPayment[i] = arrayLastPayment[i+1];
        }
        delete arrayLastPayment[arrayLastPayment.length-1];
        arrayLastPayment.length--;
        return arrayLastPayment;
    }

    function checkStopBuyTokens(uint256 _date) public returns(bool) {
        uint256 timeLastPayment = arrayLastPayment[arrayLastPayment.length-1];
        require (_date > timeLastPayment);
        uint8 countLastInvestorPerDay = 0;
        if (stopBuyTokens == false) {
            for (uint256 i = 0; i < arrayLastPayment.length-1; i++){
                if ( _date - arrayLastPayment[i] < 1 days  ) {
                    countLastInvestorPerDay++;
                }
            }
            if (countLastInvestorPerDay < MIN_NUMBER_SALES_TOKENS || houses[currentHouse].lastFloor >= MAX_NUMBER_FLOOR_PER_HOUSE) {
                stopBuyTokens = true;
                closeBuyTokens();
            }
        } else {
            if (_date > timeLastPayment + 1 days) {
                stopBuyTokens = false;
                currentHouse++;
                initHouse(currentHouse, averagePriceToken);
            }
        }
        return stopBuyTokens;
    }

    function closeBuyTokens() public returns(bool) {
        uint256 currentRaisedEth = getTotalEthPerHouse(currentHouse);

        uint256 amountToAdministration = currentRaisedEth.mul(PERCENT_TO_ADMINISTRATION).div(100);
        uint256 totalPercent = PERCENT_TO_ADMINISTRATION + PERCENT_TO_LAST_TEN_INVESTOR + PERCENT_TO_LAST_INVESTOR;
        uint256 transferEth = currentRaisedEth.mul(totalPercent).div(100);
        uint256 freeEth = currentRaisedEth.sub(transferEth);
        averagePriceToken = freeEth.div(getTotalTokenPerHouse(currentHouse));
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
        return NUMBER_TOKENS_PER_FLOOR.sub(houses[_numberHouse].paymentTokenPerFloor);
    }

    function getTotalEthPerHouse(uint256 _numberHouse) public view returns(uint256 tokens) {
        return houses[_numberHouse].totalEth;
    }

    function getTotalTokenPerHouse(uint256 _numberHouse) public view returns(uint256 tokens) {
        return houses[_numberHouse].paymentTokenTotal;
    }

    function getBuyToken(uint256 _amountEth) public returns(uint256 tokens, uint256 remainEth) {
        require(_amountEth > 0);
        uint256 eths = 0;
        (tokens, eths) = checkBuyTokenPerFloor(_amountEth);
        uint256 freeEth = _amountEth.sub(eths);
        uint256 priceToken = houses[currentHouse].priceToken;
        uint256 addBuyToken = 0;
        writePurchaise(priceToken, eths, tokens);

        while (freeEth > 0) {
            if (nextFloor()) {
                priceToken = priceToken.mul(TOKENS_COST_INCREASE_RATIO).div(100);
                addBuyToken = freeEth.div(priceToken);
                if (addBuyToken > NUMBER_TOKENS_PER_FLOOR) {
                    tokens = tokens.add(NUMBER_TOKENS_PER_FLOOR);
                    eths = eths.add(NUMBER_TOKENS_PER_FLOOR.mul(priceToken));
                    freeEth = freeEth.sub(eths);
                } else {
                    tokens = tokens.add(addBuyToken);
                    eths = eths.add(freeEth);
                    freeEth = 0;
                    remainEth = 0;
                }
                writePurchaise(priceToken, eths, tokens);
            } else {
                remainEth = freeEth;
            }
        }
    }

    function getSaleToken(address _investor, uint256 _date) public returns(bool result) {
        require(_investor != address(0));
        result = false;
        if (stopBuyTokens) {
            saleToken(_investor, _date);
            result = true;
        }
    }

    function saleToken(address _investor, uint256 _date) internal {
        require(_investor != address(0));
        Investor storage inv = investors[_investor];
        uint256 refundEth = inv.amountToken.mul(averagePriceToken);
        uint256 countStep = currentHouse.sub(inv.numberHouse);
        uint256 amountWallet = 0;
        if (address(this).balance > refundEth){
            if (countStep == 0) {
                amountWallet = refundEth.mul(PERCENT_TO_WALLET).div(100);
            } else {
                if (0 < countStep && countStep < PERCENT_TO_WALLET) {
                    countStep++;
                    amountWallet = refundEth.mul(PERCENT_TO_WALLET).mul(countStep).div(100);
                } else {
                    amountWallet = refundEth;
                }
            }
            houses[currentHouse].refundToken =  houses[currentHouse].refundToken.add(inv.amountToken);
            inv.amountToken = 0;
            inv.refundEth = inv.refundEth.add(refundEth.sub(amountWallet));
            inv.sellTime = _date;

            wallet.transfer(amountWallet);
            _investor.transfer(refundEth.sub(amountWallet));
        }
    }

    function writePurchaise(uint256 _priceToken, uint256 _amountEth, uint256 _amountToken) public {
        require(_amountEth > 0);
        require(_amountToken > 0);

        houses[currentHouse].priceToken = _priceToken;
        houses[currentHouse].totalEth = houses[currentHouse].totalEth.add(_amountEth);
        houses[currentHouse].paymentTokenPerFloor = houses[currentHouse].paymentTokenPerFloor.add(_amountToken);
        houses[currentHouse].paymentTokenTotal = houses[currentHouse].paymentTokenTotal.add(_amountToken);
    }

    function nextFloor() public returns (bool result){
        houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
        if (houses[currentHouse].lastFloor < MAX_NUMBER_FLOOR_PER_HOUSE) {
            result = true;
        } else {
            result = false;
        }
    }

}

contract DreamCity is Ownable, HouseStorage {
    using SafeMath for uint256;

    uint256 public totalEth = 0;
    uint256 public tokenAllocated = 0;

    uint256 simulateDate = 0;

    uint256 FIRST_PRICE_TOKEN = 0.05 ether;
    uint256 ETH_FOR_SALE_TOKEN = 0.0001 ether;


    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event CurrentPeriod(uint period);
    event ChangeTime(address indexed owner, uint256 newValue, uint256 oldValue);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event ChangeRate(address indexed owner, uint256 newValue, uint256 oldValue);
    event Burn(address indexed burner, uint256 value);
    event HardCapReached();


    constructor(address _owner) public
    {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // for test's
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
    }

    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = 0;
        uint256 remainEth = 0;
        (tokens, remainEth) = getBuyToken(weiAmount);
        if (tokens == 0) {revert();}

        uint256 currentDate = getCurrentDate();
        if (!checkStopBuyTokens(currentDate)) {
            totalEth = totalEth.add(weiAmount);
            tokenAllocated = tokenAllocated.add(tokens);
            setTimePayment(currentDate);

            if (checkNewInvestor(_investor)) {
                newInvestor(_investor, weiAmount, tokens, currentDate);
            } else {
                addFundToInvestor(_investor, weiAmount, tokens, currentDate);
            }
            emit TokenPurchase(_investor, weiAmount, tokens);
            refundEth(_investor, remainEth);
            wallet.transfer(weiAmount);
        }
    }

    function saleTokens(address _investor) public payable {
        require(_investor != address(0));
        require(msg.value == ETH_FOR_SALE_TOKEN);
        uint256 currentDate = getCurrentDate();
        require(getSaleToken(_investor, currentDate));
    }

    function getCurrentDate() public view returns (uint256) {
        if (simulateDate > 0) {
            return simulateDate;
        }
        return now;
    }

    function setSimulateDate(uint256 _newDate) public onlyOwner {
        require(_newDate >= 0);
        simulateDate = _newDate;
    }

}

