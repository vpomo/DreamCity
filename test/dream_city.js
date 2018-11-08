var DreamCity = artifacts.require("./DreamCity.sol");
//import assertRevert from './helpers/assertRevert';


contract('DreamCity', (accounts) => {
    var contract;
var owner = accounts[0]; // for test
var decimal = 1e18;

var buyEthOne = 0.6*decimal;
var buyEthTwo = 1.2*decimal;
var buyEthThree = 50*decimal;

    it('should deployed contract', async ()  => {
        assert.equal(undefined, contract);
        contract = await DreamCity.deployed();
        assert.notEqual(undefined, contract);
    });

    it('get address contract', async ()  => {
        assert.notEqual(undefined, contract.address);
    });

    it('token purchase check', async ()  => {
        await contract.setSimulateDate(1541066480); //Thu, 01 Nov 2018 10:01:20 GMT
        await contract.setStartDate(1541066400); //Thu, 01 Nov 2018 10:00:00 GMT

        await contract.buyTokens(accounts[1], {from:accounts[1], value: buyEthOne});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
        // assert.equal(0.6, mainInfoInvestor[0]/decimal); //investmentEth
        // assert.equal(12, Number(mainInfoInvestor[2])); //amountToken
        assert.equal(0.6, mainInfoInvestor.investmentEth/decimal); //investmentEth
        assert.equal(12, Number(mainInfoInvestor.amountToken)); //amountToken



        var houseInfo = await contract.houseInfo.call(1);
        //console.log(houseInfo, JSON.stringify(houseInfo));
        // assert.equal(12, Number(houseInfo[0])); //paymentTokenPerFloor
        // assert.equal(12, Number(houseInfo[1])); //paymentTokenTotal
        // assert.equal(0.05, Number(houseInfo[2]/decimal)); //priceToken
        assert.equal(12, Number(houseInfo.paymentTokenPerFloor)); //paymentTokenPerFloor
        assert.equal(12, Number(houseInfo.paymentTokenTotal)); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo.priceToken/decimal)); //priceToken

        //var check = await contract.buyTokens.call(accounts[2], {from:accounts[2], value: buyEthTwo});
        //console.log("check", Number(check));
        //var check = await contract.getBuyToken.call(buyEthTwo, {from:accounts[2]});
        //console.log("check", JSON.stringify(check));
        // var check = await contract.checkStopBuyTokens.call(1541066480, {from:accounts[2]});
        // console.log("check", check);

         await contract.buyTokens(accounts[2], {from:accounts[2], value: buyEthTwo});
         mainInfoInvestor = await contract.investorMainInfo.call(accounts[2]);
         //console.log("mainInfoInvestor", JSON.stringify(mainInfoInvestor));
         assert.equal(1.2, mainInfoInvestor[0]/decimal); //investmentEth
         assert.equal(24, Number(mainInfoInvestor[2])); //amountToken

        var houseInfo = await contract.houseInfo.call(1);
        //console.log(houseInfo, JSON.stringify(houseInfo));
        assert.equal(36, Number(houseInfo.paymentTokenPerFloor)); //paymentTokenPerFloor
        assert.equal(36, Number(houseInfo.paymentTokenTotal)); //paymentTokenTotal
        assert.equal(0.05, Number(houseInfo.priceToken/decimal)); //priceToken
        // for(var j =0; j < 10; j++){
        //     await contract.buyTokens(accounts[j], {from:accounts[j], value: buyEthOne});
        // }

        // await contract.setSimulateDate(1541154000); //Fri, 02 Nov 2018 10:20:00 GMT
        // for(var j =0; j < 10; j++){
        //     await contract.buyTokens(accounts[j], {from:accounts[j], value: buyEthOne});
        // };
    });



    it('check next floor', async ()  => {
        await contract.setSimulateDate(1541240400); //Sat, 03 Nov 2018 10:20:00 GMT
        var houseInfo = await contract.houseInfo.call(1);
//        console.log("houseInfo", JSON.stringify(houseInfo));
        console.log("houseInfo.paymentTokenPerFloor", Number(houseInfo.paymentTokenPerFloor));
        console.log("houseInfo.paymentTokenTotal", Number(houseInfo.paymentTokenTotal));
        console.log("houseInfo.priceToken", Number(houseInfo.priceToken/decimal));
        console.log("houseInfo.lastFloor", Number(houseInfo.lastFloor));
        console.log("houseInfo.totalEth", Number(houseInfo.totalEth));
        // console.log("paymentTokenPerFloor", Number(houseInfo[0]));
        // console.log("paymentTokenTotal", Number(houseInfo[1]));
        // console.log("priceToken", Number(houseInfo[2]/decimal));
        // console.log("lastFloor", Number(houseInfo[3]));

        var check = await contract.checkBuyTokenPerFloor.call(buyEthThree, {from:accounts[4]});
        //console.log("check", JSON.stringify(check));
        console.log("checkBuyTokenPerFloor.tokens", Number(check.tokens));
        console.log("checkBuyTokenPerFloor.needEth", Number(check.needEth/decimal));

        check = await contract.getBuyToken.call(buyEthThree, {from:accounts[4]});
        //console.log("check", JSON.stringify(check));
        console.log("getBuyToken.totalTokens", Number(check.totalTokens));
        console.log("getBuyToken.remainEth", Number(check.remainEth/decimal));

        await contract.buyTokens(accounts[4], {from:accounts[4], value: buyEthThree});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[4]);
        console.log("mainInfoInvestor", JSON.stringify(mainInfoInvestor));
        console.log("investmentEth", mainInfoInvestor.investmentEth/decimal); //investmentEth
        console.log("amountToken", Number(mainInfoInvestor.amountToken)); //amountToken

        houseInfo = await contract.houseInfo.call(1);
//        console.log("houseInfo", JSON.stringify(houseInfo));
        console.log("houseInfo.paymentTokenPerFloor", Number(houseInfo.paymentTokenPerFloor));
        console.log("houseInfo.paymentTokenTotal", Number(houseInfo.paymentTokenTotal));
        console.log("houseInfo.priceToken", Number(houseInfo.priceToken/decimal));
        console.log("houseInfo.lastFloor", Number(houseInfo.lastFloor));
        console.log("houseInfo.totalEth", Number(houseInfo.totalEth));

        // for(var j =0; j < 1; j++){
        //     for(var i = 0; i < 10; i++) {
        //         await contract.buyTokens(accounts[i], {from:accounts[i], value: buyEthOne});
        //     };
        // };

    });


});



