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


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
    * Protection against short address attack
    */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "DreamCityToken";
    string public constant symbol = "DCT";
    uint8 public constant decimals = 18;
    mapping(uint8 => uint8) public approveOwner;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * Peterson's Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit Transfer(_token, owner, balance);
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


    array[] arrayLastInvestors;

    struct Investor {
        uint256 investmentEth;
        uint256 amountToken;
        uint256 paymentTime;
    }

    mapping (address => Investor) private investors;

    constructor() public {
    }

    function newInvestor(address _investor, uint256 _investment, uint256 _amountToken, uint256 _paymentTime) public returns (bool) {
        Investor inv = investors[_investor];
        if (!checkNewInvestor(_investor)) {
            return false;
        }
        addFundToInvestor(_investor, _investment, _amountToken, _paymentTime);
        countInvestors++;
        return true;
    }

    function checkNewInvestor(address _investor) public view returns (bool) {
        Investor inv = investors[_investor];
        if (inv.paymentTime > 0 && inv.investment > 0) {
            return false;
        }
        return true;
    }

    function addFundToInvestor(address _investor, uint256 _investment, uint256 _amountToken, uint256 _paymentTime) public {
        Investor storage inv = investors[_investor];
        inv.investment = inv.investment.add(_investment);
        inv.amountToken = inv.amountToken.add(_amountToken);
        inv.paymentTime = _paymentTime;
        currentRaisedEth = currentRaisedEth.add(_investment);
        setLastInvestor(_investor);
    }

    function setLastInvestor(address _investor) public {
        require(_investor != address(0));
        if (arrayLastInvestors.length > NUMBER_LAST_INVESTORS) {
            arrayLastInvestors = removeElemLastAddressInvestors(0);
        }
        arrayLastInvestors.push(_investor);
    }

    function removeElemLastAddressInvestors(uint index) internal returns(uint[]) {
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
            for (uint i = index; i<arrayLastInvestors.length-1; i++){
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

    uint256 public NUMBER_TOKENS_PER_FLOOR = 1000;
    uint256 public MIN_NUMBER_SALES_TOKENS = 6;
    uint256 public TOKENS_COST_INCREASE_RATIO = 105;
    uint256 public PERCENT_TO_ADMINISTRATION = 8;

    address public administrationWallet;

    bool public stopBuyTokens = false;

    uint256 public currentHouse;

    struct House {
        uint256 lastFloor;
        uint256 paymentTokenPerFloor;
        uint256 paymentTokenTotal;
        uint256 totalEth;
        uint256 priceToken;
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
        uint256 lastFloor, uint256 paymentTokenPerFloor, uint256 amountEth
    ) {
        lastFloor = houses[_numberHouse].lastFloor;
        paymentTokenPerFloor = houses[_numberHouse].paymentTokenPerFloor;
        amountEth = houses[_numberHouse].amountEth;
    }

    function validBuyToken(uint256 _date) public view returns (
        uint256 lastFloor, uint256 paymentTokenPerFloor, uint256 paymentTokenTotal
    ) {

        lastFloor = houses[_numberHouse].lastFloor;
        paymentTokenPerFloor = houses[_numberHouse].paymentTokenPerFloor;
        paymentTokenTotal = houses[_numberHouse].paymentTokenTotal;
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
            if (countLastInvestorPerDay < MIN_NUMBER_SALES_TOKENS) {
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

    function checkBuyTokenPerFloor(uint256 _amountEth) public returns(uint256 tokens, uint256 needEth) {
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

    function getFreeTokenPerFloor(uint256 _numberHouse) public returns(uint256 tokens) {
        return NUMBER_TOKENS_PER_FLOOR.sub(houses[_numberHouse].paymentTokenPerFloor);
    }

    function getTotalEthPerHouse(uint256 _numberHouse) public returns(uint256 tokens) {
        return houses[_numberHouse].totalEth;
    }

    function getTotalTokenPerHouse(uint256 _numberHouse) public returns(uint256 tokens) {
        return houses[_numberHouse].paymentTokenTotal;
    }

    function getBuyToken(uint256 _amountEth) public returns(uint256 tokens, uint8 nextFloor) {
        require(_amountEth > 0);
        (tokens, eths) = checkBuyTokenPerFloor(_amountEth);
        uint256 freeEth = _amountEth.sub(eths);
        uint256 priceToken = houses[currentHouse].priceToken;
        uint256 addBuyToken = 0;
        writePurchaise(priceToken, eths, tokens);

        while (freeEth > 0) {
            nextFloor();
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
            }
            writePurchaise(priceToken, eths, tokens);
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

    function nextFloor() public {
        houses[currentHouse].lastFloor = houses[currentHouse].lastFloor.add(1);
    }

}

contract DreamCity is Ownable, InvestorStorage, MintableToken {
    using SafeMath for uint256;

    uint256 public totalEth = 0;
    uint256 public tokenAllocated = 0;


    uint256 public currentPriceToken;
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
        transfersEnabled = true;
        mintingFinished = false;
        currPriceToken = FIRST_PRICE_TOKEN;
        initHouse(0, FIRST_PRICE_TOKEN);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        if (msg.value >= currPriceToken) {
            buyTokens(msg.sender);
        } else if (msg.value == ETH_FOR_SALE_TOKEN) {
            if (saleTokens(msg.sender) == 0) {
                refundEth(msg.sender, msg.value);
            }
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
        uint256 tokens = getBuyToken(weiAmount);
        if (tokens == 0) {revert();}

        uint256 currentDate = getCurrentDate();
        if (!checkStopBuyTokens(currentDate)) {
            totalEth = totalEth.add(weiAmount);
            tokenAllocated = tokenAllocated.add(tokens);
            setTimePayment(currentDate);
            mint(_investor, tokens, owner);

            if (checkNewInvestor(_investor)) {
                newInvestor(_investor, weiAmount, tokens, currentDate);
            } else {
                addFundToInvestor(_investor, weiAmount, tokens, currentDate);
            }
            emit TokenPurchase(_investor, weiAmount, tokens);
            wallet.transfer(weiAmount);
        }
    }

    function saleTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 tokens = validSaleTokens(_investor);

        return tokens;
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > balances[owner]) {
            emit TokenLimitReached(msg.sender, tokenAllocated, addTokens);
            return 0;
        }

        return addTokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal returns (uint256) {
        uint256 amountOfTokens = 0;
        amountOfTokens = _weiAmount.mul(currentPriceToken);

        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        return 0;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForFund(address _walletOwner) internal returns (bool result) {
        result = false;
        require(_walletOwner != address(0));
        balances[_walletOwner] = balances[_walletOwner].add(fundForSale);
        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        result = true;
    }

    function getDeposited(address _investor) external view returns (uint256){
        return deposited[_investor];
    }

    function validSaleTokens(address _investor) public returns (uint256) {
        uint256 saleTokens = 0;
        return saleTokens;
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

