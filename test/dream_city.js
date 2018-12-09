var DreamCity = artifacts.require("./DreamCity.sol");
//import assertRevert from './helpers/assertRevert';


contract('DreamCity', (accounts) => {
    var contract;
var owner = accounts[0]; // for test
var decimal = 1e18;

var buyEthOne = 0.6*decimal;
var buyEthTwo = 1.2*decimal;
var buyEthThree = 50*decimal;
var buyEthFor = 15.2*decimal;

var saleEthOne = 0.0001*decimal;

it('should deployed contract', async ()  => {
    assert.equal(undefined, contract);
contract = await DreamCity.deployed();
assert.notEqual(undefined, contract);
});

it('get address contract', async ()  => {
    assert.notEqual(undefined, contract.address);
});

it('token purchase check', async ()  => {
        await contract.setDemo(); //Thu, 01 Nov 2018 10:01:20 GMT
        await contract.setStartDate(1541066400); //Thu, 01 Nov 2018 10:00:00 GMT
        await contract.setSimulateDate(1541066480); //Thu, 01 Nov 2018 10:01:20 GMT

        var stopBuyToken = await contract.checkStopBuyTokens.call(1541066480, {from:accounts[4]});
        assert.equal(false, stopBuyToken);
        //console.log("stopBuyToken", stopBuyToken);

        await contract.buyTokens(accounts[1], {from:accounts[1], value: buyEthOne});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
        assert.equal(0.6, mainInfoInvestor[0]/decimal); //investmentEth
        assert.equal(12, Number(mainInfoInvestor[2])); //amountToken


        var houseInfo = await contract.houseInfo.call(1);
        assert.equal(12, Number(houseInfo[0])); //paymentTokenPerFloor
        assert.equal(12, Number(houseInfo[1])); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo[2]/decimal)); //priceToken
        assert.equal(12, Number(houseInfo[0])); //paymentTokenPerFloor
        assert.equal(12, Number(houseInfo[1])); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo[2]/decimal)); //priceToken

        await contract.buyTokens(accounts[2], {from:accounts[2], value: buyEthTwo});
        mainInfoInvestor = await contract.investorMainInfo.call(accounts[2]);
        assert.equal(1.2, mainInfoInvestor[0]/decimal); //investmentEth
        assert.equal(24, Number(mainInfoInvestor[2])); //amountToken

        var houseInfo = await contract.houseInfo.call(1);
        assert.equal(36, Number(houseInfo[0])); //paymentTokenPerFloor
        assert.equal(36, Number(houseInfo[1])); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo[2]/decimal)); //priceToken
});


it('check next floor', async ()  => {
    var houseInfo = await contract.houseInfo.call(1);

assert.equal(36, Number(houseInfo[0]));//paymentTokenPerFloor
assert.equal(36, Number(houseInfo[1]));//paymentTokenTotal
assert.equal(0.05, Number(houseInfo[2]/decimal));//priceToken
assert.equal(0, Number(houseInfo[3]));//lastFloor
assert.equal(1.8, Number(houseInfo[4]/decimal));//totalEth

// console.log("paymentTokenPerFloor", Number(houseInfo[0]));
// console.log("paymentTokenTotal", Number(houseInfo[1]));
// console.log("priceToken", Number(houseInfo[2]/decimal));
// console.log("lastFloor", Number(houseInfo[3]));

var check = await contract.checkBuyTokenPerFloor.call(buyEthThree, {from:accounts[4]});
//console.log("check", JSON.stringify(check));
// console.log("checkBuyTokenPerFloor.tokens", Number(check.tokens));
// console.log("checkBuyTokenPerFloor.needEth", Number(check.needEth/decimal));
assert.equal(264, Number(check[0]));//tokens
assert.equal(13.2, Number(check[1]/decimal));//needEth

check = await contract.getBuyToken.call(buyEthThree, {from:accounts[4]});
//console.log("check", JSON.stringify(check));
// console.log("getBuyToken.totalTokens", Number(check.totalTokens));
// console.log("getBuyToken.remainEth", Number(check.remainEth/decimal));
assert.equal(864, Number(check[0]));//totalTokens
assert.equal(4.5125, Number(check[1]/decimal));//remainEth

var stopBuyToken = await contract.checkStopBuyTokens.call(1541066680, {from:accounts[4]});
//console.log("stopBuyToken", stopBuyToken);
assert.equal(false, stopBuyToken);

await contract.buyTokens(accounts[4], {from:accounts[4], value: buyEthThree});

var mainInfoInvestor = await contract.investorMainInfo.call(accounts[4]);
assert.equal(45.4875, mainInfoInvestor[0]/decimal); //investmentEth
assert.equal(864, Number(mainInfoInvestor[2])); //amountToken

houseInfo = await contract.houseInfo.call(1);
assert.equal(300, Number(houseInfo[0]));//paymentTokenPerFloor
assert.equal(900, Number(houseInfo[1]));//paymentTokenTotal
assert.equal(0.055125, Number(houseInfo[2]/decimal));//priceToken
assert.equal(2, Number(houseInfo[3]));//lastFloor
assert.equal(47.2875, Number(houseInfo[4]/decimal));//totalEth

});


it('check stop buy tokens last floor', async ()  => {
    var currentRaisedEth = await contract.getTotalEthPerHouse.call(1);
assert.equal(47.2875, Number(currentRaisedEth/decimal));

var getBuyToken = await contract.getBuyToken.call(buyEthOne, {from:accounts[5]});
assert.equal(true, getBuyToken[2]);//lastFloorPerHouse
assert.equal(0, Number(getBuyToken[0]));//totalTokens
assert.equal(buyEthOne, Number(getBuyToken[1]));//remainEth

getBuyToken = await contract.getBuyToken(buyEthOne, {from:accounts[5]});

var stopBuyToken = await contract.stopBuyTokens.call();
assert.equal(true, stopBuyToken);

stopBuyToken = await contract.checkStopBuyTokens.call(1541066490, {from:accounts[4]});
assert.equal(true, stopBuyToken);
currentRaisedEth = await contract.getTotalEthPerHouse.call(1);
assert.equal(47.2875, Number(currentRaisedEth/decimal));

});


it('check sale token', async ()  => {
    await contract.setSimulateDate(1541124000); //Fri, 02 Nov 2018 02:00:00 GMT

    var stopBuyToken = await contract.checkStopBuyTokens.call(1541124000, {from:accounts[4]});
    assert.equal(true, stopBuyToken);

    await contract.buyTokens(accounts[9], {from:accounts[9], value: buyEthTwo});
    var mainInfoInvestor = await contract.investorMainInfo.call(accounts[9]);
    assert.equal(0, mainInfoInvestor[0]/decimal); //investmentEth
    assert.equal(0, Number(mainInfoInvestor[2])); //amountToken

    // var getBuyToken = await contract.getBuyToken.call(buyEthOne, {from:accounts[5]});
    // console.log("getBuyToken.totalTokens", Number(getBuyToken[0]));

    var averagePriceToken = await contract.averagePriceToken.call();
    //console.log("averagePriceToken", Number(averagePriceToken));

    await contract.buyTokens(accounts[1], {from:accounts[1], value: saleEthOne});
    //await contract.saleTokens(accounts[1], {from:accounts[1], value: saleEthOne});
    var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
    // console.log("refundEth", mainInfoInvestor.refundEth/decimal); //refundEth
    assert.equal(0, Number(mainInfoInvestor[2]));//amountToken
    assert.equal(0.5044, mainInfoInvestor[1]/decimal);//refundEth

    var houseInfo = await contract.houseInfo.call(1);
    // console.log("houseInfo.refundEth", Number(houseInfo.refundEth/decimal));
    assert.equal(4.8580025, Number(houseInfo[5]/decimal));//refundEth

    //await contract.buyTokens(accounts[2], {from:accounts[2], value: buyEthOne});
    mainInfoInvestor = await contract.investorMainInfo.call(accounts[2]);
    assert.equal(24, Number(mainInfoInvestor[2])); //amountToken

    await contract.buyTokens(accounts[2], {from:accounts[2], value: saleEthOne});
    await contract.buyTokens(accounts[4], {from:accounts[4], value: saleEthOne});

    var houseInfo = await contract.houseInfo.call(2);
    console.log("houseInfo.paymentTokenPerFloor", Number(houseInfo[0])); //paymentTokenPerFloor

    var tokenAllocated = await contract.tokenAllocated.call();
    console.log("tokenAllocated", Number(tokenAllocated)); //tokenAllocated

    await contract.setSimulateDate(1541210400); //03 Nov 2018 02:00:00 GMT
    await contract.buyTokens(accounts[3], {from:accounts[3], value: buyEthOne});

    var finishProject = await contract.finishProject.call();
    console.log("finishProject", finishProject); //finishProject

    await contract.claimEth();

// await contract.addToAdminlist(accounts[8]);
    // await contract.buyTokens(accounts[8], {from:accounts[8], value: buyEthTwo});
    // mainInfoInvestor = await contract.investorMainInfo.call(accounts[8]);
    // assert.equal(28, Number(mainInfoInvestor[2])); //amountToken
});

/*

it('check start buy token for (day + 1) after stop buy token', async ()  => {
    var totalFloorBuilded = await contract.totalFloorBuilded.call();
    assert.equal(3, Number(totalFloorBuilded));

    await contract.setSimulateDate(1541206800); //Sat, 03 Nov 2018 01:00:00 GMT
//var stopBuyToken = await contract.stopBuyTokens.call();

var stopBuyToken = await contract.checkStopBuyTokens.call(1541206800, {from:accounts[4]});
assert.equal(false, stopBuyToken);

houseInfo = await contract.houseInfo.call(2);
// Amount token per floor
assert.equal(916, Number(houseInfo[0]));//paymentTokenPerFloor
assert.equal(916, Number(houseInfo[1]));//paymentTokenTotal

await contract.buyTokens(accounts[6], {from:accounts[6], value: buyEthOne});

var averagePriceToken = await contract.averagePriceToken.call();

var houseInfo = await contract.houseInfo.call(2);
var priceToken = houseInfo[2];//priceToken
assert.equal(44135000000000000, Number(priceToken));
//console.log("priceToken", Number(priceToken), Number(averagePriceToken*1.05));

var freeEth = await contract.getDifferentEth.call(13, buyEthOne, priceToken);
//console.log("freeEth", Number(freeEth/decimal));
assert.equal(0.02624500000000001 ,Number(freeEth/decimal));

var mainInfoInvestor = await contract.investorMainInfo.call(accounts[6]);
// console.log("mainInfoInvestor.investmentEth", Number(mainInfoInvestor.investmentEth/decimal));
// console.log("mainInfoInvestor.amountToken", Number(mainInfoInvestor.amountToken));
assert.equal(0.573755, Number(mainInfoInvestor[0]/decimal));//investmentEth
assert.equal(13, Number(mainInfoInvestor[2]));//amountToken

houseInfo = await contract.houseInfo.call(2);
// console.log("houseInfo.paymentTokenPerFloor", Number(houseInfo[0]));
// console.log("houseInfo.paymentTokenTotal", Number(houseInfo[1]));
// console.log("houseInfo.priceToken", Number(houseInfo[2]/decimal));
// console.log("houseInfo.lastFloor", Number(houseInfo[3]));
// console.log("houseInfo.totalEth", Number(houseInfo[4]/decimal));

assert.equal(13, Number(houseInfo[0]));//paymentTokenPerFloor
assert.equal(929, Number(houseInfo[1]));//paymentTokenTotal
assert.equal(priceToken/decimal, Number(houseInfo[2]/decimal));//priceToken
assert.equal(1, Number(houseInfo[3]));//lastFloor

var amountTokenLastDay = await contract.getAmountTokenLastDay.call();
assert.equal(13, Number(amountTokenLastDay));
//console.log("amountTokenLastDay", Number(amountTokenLastDay));

var member = await contract.getMemberArrayPaidTokenLastDay.call(0);
assert.equal(28, member[1]);//amountToken
assert.equal(1541124000, member[2]);//amountToken
// console.log("member.investor", member.investor);//paymentTime
// console.log("member.amountToken", Number(member.amountToken));
// console.log("member.paymentTime", Number(member.paymentTime));

var totalEthPerHouse = await contract.totalEthPerHouse.call();
//console.log("totalEthPerHouse", Number(totalEthPerHouse));
assert.equal(1.750688333333333200, Number(totalEthPerHouse/decimal));

totalFloorBuilded = await contract.totalFloorBuilded.call();
assert.equal(4, Number(totalFloorBuilded));

});

it('check buy token, if free token for current floor equals 0', async ()  => {
    await contract.buyTokens(accounts[8], {from:accounts[8], value: 39.85391*decimal});

var check = await contract.checkBuyTokenPerFloor.call(39.85391*decimal, {from:accounts[8]});
assert.equal(0, Number(check[0]));
assert.equal(0, Number(check[1]));
// console.log("check.tokens", Number(check[0]));
// console.log("check.needEth", Number(check[1]/decimal));

await contract.buyTokens(accounts[9], {from:accounts[9], value: buyEthOne});

var mainInfoInvestor = await contract.investorMainInfo.call(accounts[9]);
// console.log("mainInfoInvestor.investmentEth", Number(mainInfoInvestor.investmentEth/decimal));
// console.log("mainInfoInvestor.amountToken", Number(mainInfoInvestor.amountToken));
assert.equal(12, Number(mainInfoInvestor[2]));//amountToken
houseInfo = await contract.houseInfo.call(2);
assert.equal(2, Number(houseInfo[3]));//lastFloor
assert.equal(1844, Number(houseInfo[1]));//paymentTokenTotal

var totalFloorBuilded = await contract.totalFloorBuilded.call();
assert.equal(5, Number(totalFloorBuilded));

await contract.buyTokens(accounts[9], {from:accounts[9], value: buyEthThree});

var stopBuyToken = await contract.stopBuyTokens.call();
assert.equal(false, stopBuyToken);

await contract.buyTokens(accounts[8], {from:accounts[8], value: buyEthOne});

stopBuyToken = await contract.stopBuyTokens.call();
assert.equal(true, stopBuyToken);

totalFloorBuilded = await contract.totalFloorBuilded.call();
assert.equal(6, Number(totalFloorBuilded));

});
*/

/*
    it('check time for change status buy token', async ()  => {
        // 1541206800 - current time // //Sat, 03 Nov 2018 01:00:00 GMT
        var numberDay = await contract.getNumberDay.call(1541206800);
        var tokensPerDay  = await contract.getPaidPerDay.call(numberDay);
        //console.log("tokensPerDay", Number(tokensPerDay));
        assert.equal(312, Number(tokensPerDay));
        var stopBuyToken = await contract.stopBuyTokens.call();
        //console.log("stopBuyToken", stopBuyToken);
        assert.equal(false, stopBuyToken);
        var freeToken = await contract.getFreeTokenPerFloor(2);
        console.log("freeToken", Number(freeToken));

        // assert.equal(true, stopBuyToken);

        // 1541293200 - checking time // Sun, 04 Nov 2018 01:00:00 GMT
        await contract.setSimulateDate(1541293200); //Sun, 04 Nov 2018 01:00:00 GMT
        await contract.buyTokens(accounts[9], {from:accounts[9], value: 0.06*decimal});
        stopBuyToken = await contract.stopBuyTokens.call();
        assert.equal(false, stopBuyToken);
        //console.log("stopBuyToken", stopBuyToken);
        numberDay = await contract.getNumberDay.call(1541293200);
        tokensPerDay  = await contract.getPaidPerDay.call(numberDay);
        //console.log("tokensPerDay", Number(tokensPerDay));
        assert.equal(1, Number(tokensPerDay));

        // 1541379600 - checking time // Mon, 05 Nov 2018 01:00:00 GMT
        await contract.setSimulateDate(1541379600); //Mon, 05 Nov 2018 01:00:00 GMT
        await contract.buyTokens(accounts[9], {from:accounts[9], value: buyEthOne});
        stopBuyToken = await contract.stopBuyTokens.call();
        assert.equal(true, stopBuyToken);
        //console.log("stopBuyToken", stopBuyToken);
        numberDay = await contract.getNumberDay.call(1541379600);
        tokensPerDay  = await contract.getPaidPerDay.call(numberDay);
        //console.log("tokensPerDay", Number(tokensPerDay));
        assert.equal(0, Number(tokensPerDay));
    });
*/

});
