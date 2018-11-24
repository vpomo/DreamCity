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
        await contract.setDemo(true); //Thu, 01 Nov 2018 10:01:20 GMT
        await contract.setStartDate(1541066400); //Thu, 01 Nov 2018 10:00:00 GMT
        await contract.setSimulateDate(1541066480); //Thu, 01 Nov 2018 10:01:20 GMT

        var stopBuyToken = await contract.checkStopBuyTokens.call(1541066480, {from:accounts[4]});
        assert.equal(false, stopBuyToken);
        //console.log("stopBuyToken", stopBuyToken);

        await contract.buyTokens(accounts[1], {from:accounts[1], value: buyEthOne});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
        assert.equal(0.6, mainInfoInvestor[0]/decimal); //investmentEth
        assert.equal(12, Number(mainInfoInvestor[2])); //amountToken
        assert.equal(0.6, mainInfoInvestor.investmentEth/decimal); //investmentEth
        assert.equal(12, Number(mainInfoInvestor.amountToken)); //amountToken



        var houseInfo = await contract.houseInfo.call(1);
        assert.equal(12, Number(houseInfo[0])); //paymentTokenPerFloor
        assert.equal(12, Number(houseInfo[1])); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo[2]/decimal)); //priceToken
        assert.equal(12, Number(houseInfo.paymentTokenPerFloor)); //paymentTokenPerFloor
        assert.equal(12, Number(houseInfo.paymentTokenTotal)); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo.priceToken/decimal)); //priceToken

         await contract.buyTokens(accounts[2], {from:accounts[2], value: buyEthTwo});
         mainInfoInvestor = await contract.investorMainInfo.call(accounts[2]);
         assert.equal(1.2, mainInfoInvestor[0]/decimal); //investmentEth
         assert.equal(24, Number(mainInfoInvestor[2])); //amountToken

        var houseInfo = await contract.houseInfo.call(1);
        assert.equal(36, Number(houseInfo.paymentTokenPerFloor)); //paymentTokenPerFloor
        assert.equal(36, Number(houseInfo.paymentTokenTotal)); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo.priceToken/decimal)); //priceToken
});


    it('check next floor', async ()  => {
        var houseInfo = await contract.houseInfo.call(1);

        assert.equal(36, Number(houseInfo.paymentTokenPerFloor));
        assert.equal(36, Number(houseInfo.paymentTokenTotal));
        assert.equal(0.05, Number(houseInfo.priceToken/decimal));
        assert.equal(0, Number(houseInfo.lastFloor));
        assert.equal(1.8, Number(houseInfo.totalEth/decimal));
        // console.log("paymentTokenPerFloor", Number(houseInfo[0]));
        // console.log("paymentTokenTotal", Number(houseInfo[1]));
        // console.log("priceToken", Number(houseInfo[2]/decimal));
        // console.log("lastFloor", Number(houseInfo[3]));

        var check = await contract.checkBuyTokenPerFloor.call(buyEthThree, {from:accounts[4]});
        //console.log("check", JSON.stringify(check));
        // console.log("checkBuyTokenPerFloor.tokens", Number(check.tokens));
        // console.log("checkBuyTokenPerFloor.needEth", Number(check.needEth/decimal));
        assert.equal(264, Number(check.tokens));
        assert.equal(13.2, Number(check.needEth/decimal));

        check = await contract.getBuyToken.call(buyEthThree, {from:accounts[4]});
        //console.log("check", JSON.stringify(check));
        // console.log("getBuyToken.totalTokens", Number(check.totalTokens));
        // console.log("getBuyToken.remainEth", Number(check.remainEth/decimal));
        assert.equal(864, Number(check.totalTokens));
        assert.equal(4.5125, Number(check.remainEth/decimal));

        var stopBuyToken = await contract.checkStopBuyTokens.call(1541066680, {from:accounts[4]});
        //console.log("stopBuyToken", stopBuyToken);
        assert.equal(false, stopBuyToken);

        await contract.buyTokens(accounts[4], {from:accounts[4], value: buyEthThree});

        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[4]);
        assert.equal(45.4875, mainInfoInvestor.investmentEth/decimal); //investmentEth
        assert.equal(864, Number(mainInfoInvestor.amountToken)); //amountToken

        houseInfo = await contract.houseInfo.call(1);
        assert.equal(300, Number(houseInfo.paymentTokenPerFloor));
        assert.equal(900, Number(houseInfo.paymentTokenTotal));
        assert.equal(0.055125, Number(houseInfo.priceToken/decimal));
        assert.equal(2, Number(houseInfo.lastFloor));
        assert.equal(47.2875, Number(houseInfo.totalEth/decimal));

    });


    it('check stop buy tokens last floor', async ()  => {
        var currentRaisedEth = await contract.getTotalEthPerHouse.call(1);
        assert.equal(47.2875, Number(currentRaisedEth/decimal));

        var getBuyToken = await contract.getBuyToken.call(buyEthOne, {from:accounts[5]});
        assert.equal(true, getBuyToken.lastFloorPerHouse);
        assert.equal(0, Number(getBuyToken.totalTokens));
        assert.equal(buyEthOne, Number(getBuyToken.remainEth));

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
        console.log("mainInfoInvestor.investmentEth", mainInfoInvestor[0]/decimal);
        console.log("mainInfoInvestor.amountToken", Number(mainInfoInvestor[2]));
        // assert.equal(1.2, mainInfoInvestor[0]/decimal); //investmentEth
        // assert.equal(24, Number(mainInfoInvestor[2])); //amountToken

        // var getBuyToken = await contract.getBuyToken.call(buyEthOne, {from:accounts[5]});
        // console.log("getBuyToken.totalTokens", Number(getBuyToken[0]));

        await contract.buyTokens(accounts[1], {from:accounts[1], value: saleEthOne});
        //await contract.saleTokens(accounts[1], {from:accounts[1], value: saleEthOne});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
        // console.log("refundEth", mainInfoInvestor.refundEth/decimal); //refundEth
        assert.equal(0, Number(mainInfoInvestor[2]));//amountToken
        assert.equal(0.510705, mainInfoInvestor.refundEth/decimal);

        var houseInfo = await contract.houseInfo.call(1);
        // console.log("houseInfo.refundEth", Number(houseInfo.refundEth/decimal));
        assert.equal(0.56745, Number(houseInfo.refundEth/decimal));

        //await contract.buyTokens(accounts[2], {from:accounts[2], value: buyEthOne});
        mainInfoInvestor = await contract.investorMainInfo.call(accounts[2]);
        assert.equal(24, Number(mainInfoInvestor.amountToken)); //amountToken

});


/*

    it('check start buy token for (day + 1) after stop buy token', async ()  => {
        await contract.setSimulateDate(1541206800); //Sat, 03 Nov 2018 01:00:00 GMT
        await contract.buyTokens(accounts[6], {from:accounts[6], value: buyEthOne});

        var averagePriceToken = await contract.averagePriceToken.call();

        var houseInfo = await contract.houseInfo.call(2);
        var priceToken = houseInfo.priceToken;
        assert.equal(Number(averagePriceToken), Number(priceToken));

        var freeEth = await contract.getDifferentEth.call(12, buyEthOne, priceToken);
        //console.log("freeEth", Number(freeEth/decimal));
        assert.equal(0.03255 ,Number(freeEth/decimal));

        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[6]);
        // console.log("mainInfoInvestor.investmentEth", Number(mainInfoInvestor.investmentEth/decimal));
        // console.log("mainInfoInvestor.amountToken", Number(mainInfoInvestor.amountToken));
        assert.equal(0.56745, Number(mainInfoInvestor.investmentEth/decimal));
        assert.equal(12, Number(mainInfoInvestor.amountToken));

        houseInfo = await contract.houseInfo.call(2);
        // console.log("houseInfo.paymentTokenPerFloor", Number(houseInfo.paymentTokenPerFloor));
        // console.log("houseInfo.paymentTokenTotal", Number(houseInfo.paymentTokenTotal));
        // console.log("houseInfo.priceToken", Number(houseInfo.priceToken/decimal));
        // console.log("houseInfo.lastFloor", Number(houseInfo.lastFloor));
        // console.log("houseInfo.totalEth", Number(houseInfo.totalEth/decimal));
        assert.equal(12, Number(houseInfo.paymentTokenPerFloor));
        assert.equal(12, Number(houseInfo.paymentTokenTotal));
        assert.equal(priceToken/decimal, Number(houseInfo.priceToken/decimal));
        assert.equal(0, Number(houseInfo.lastFloor));
        assert.equal(0.56745, Number(houseInfo.totalEth/decimal));

        await contract.buyTokens(accounts[7], {from:accounts[7], value: buyEthOne});
        await contract.buyTokens(accounts[8], {from:accounts[8], value: buyEthTwo});

        var amountTokenLastDay = await contract.getAmountTokenLastDay.call();
        assert.equal(49, Number(amountTokenLastDay));
        //console.log("amountTokenLastDay", Number(amountTokenLastDay));

        var houseInfo = await contract.houseInfo.call(2);
        assert.equal(49, Number(houseInfo[0])); //paymentTokenPerFloor
        assert.equal(49, Number(houseInfo[1])); //paymentTokenTotal
        assert.equal(0.0472875, Number(houseInfo[2]/decimal)); //priceToken

        // console.log("paymentTokenPerFloor", Number(houseInfo[0]));
        // console.log("paymentTokenTotal", Number(houseInfo[1]));
        // console.log("priceToken", Number(houseInfo[2]/decimal));

        var member = await contract.getMemberArrayPaidTokenLastDay.call(0);
        assert.equal(12, member[1]);//amountToken
        // console.log("member.investor", member.investor);
        // console.log("member.amountToken", Number(member.amountToken));
        // console.log("member.paymentTime", Number(member.paymentTime));

        member = await contract.getMemberArrayPaidTokenLastDay.call(1);
        assert.equal(12, member[1]);//amountToken
        member = await contract.getMemberArrayPaidTokenLastDay.call(2);
        assert.equal(25, member[1]);//amountToken

        // member = await contract.getMemberArrayPaidTokenLastDay.call(1);
        // console.log("member.investor", member.investor);
        // console.log("member.amountToken", Number(member.amountToken));
        // console.log("member.paymentTime", Number(member.paymentTime));
        var totalEthPerHouse = await contract.totalEthPerHouse.call();
        assert.equal(2.3170875, Number(totalEthPerHouse/decimal));

    });

    it('check buy token, if free token for current floor equals 0', async ()  => {
        await contract.buyTokens(accounts[8], {from:accounts[8], value: 11.87*decimal});

        var check = await contract.checkBuyTokenPerFloor.call(11.87*decimal, {from:accounts[8]});
        assert.equal(0, Number(check[0]));
        assert.equal(0, Number(check[1]));
        // console.log("check.tokens", Number(check[0]));
        // console.log("check.needEth", Number(check[1]/decimal));

        await contract.buyTokens(accounts[9], {from:accounts[9], value: buyEthOne});

        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[9]);
        assert.equal(12, Number(mainInfoInvestor[2]));//amountToken

    });

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

