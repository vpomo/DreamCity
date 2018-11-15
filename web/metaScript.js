var adrressContractRopsten = "0xe4a60882c473e008b4e1c942bd73addf50483825";
var adrressContractMain = "0xe4a60882c473e008b4e1c942bd73addf50483825";
var contract;

var decimal = 1e18;

window.addEventListener('load', function () {
    // Checking if Web3 has been injected by the browser (Mist/MetaMask)
    if (typeof web3 !== 'undefined') {
        // Use Mist/MetaMask's provider
        console.log("Web3 detected!");
        window.web3 = new Web3(web3.currentProvider);
        // Now you can start your app & access web3 freely:
        var currentNetwork = web3.version.network;
        startApp();
    } else {
        console.log("Please use Chrome or Firefox, install the Metamask extension and retry the request!");
    }
})

function startApp() {
    contract = initContract();
    var myWalletAddress = web3.eth.accounts[0];

    contract.currentHouse( function (error, data) {
        var currHouse = data;
        console.log("currentHouse = " + currentHouse);
        contract.houseInfo(currHouse, function (error, dataHouse) {
            var houseInfo = dataHouse;
            console.log("houseInfo = " + JSON.stringify(houseInfo));

            var priceToken = houseInfo.priceToken / decimal;
            $('#priceToken').html(priceToken.toFixed(4));

            var priceTokenNext = priceToken * 1.05;
            $('#priceTokenNext').html(priceTokenNext.toFixed(4));

            var lastFloor = houseInfo.lastFloor + 1;
            $('#lastFloor').html(lastFloor.toFixed(0));

            var paymentTokenTotal = houseInfo.paymentTokenTotal;
            $('#paymentTokenTotal').html(paymentTokenTotal.toFixed(0));
            var totalEth = houseInfo.totalEth / decimal;
            $('#totalEth').html(totalEth.toFixed(4));
        });

        contract.houseTimeInfo(currHouse, function (error, dataTimeInfo) {
            console.log("houseTimeInfo = " + JSON.stringify(dataTimeInfo));

            var startTimeBuild = dataTimeInfo.startTimeBuild;
            var stopTimeBuild = dataTimeInfo.stopTimeBuild;
            var startTimeBuildNext = dataTimeInfo.stopTimeBuild + 86401;

            $('#startTimeBuild').html(startTimeBuild);
            $('#stopTimeBuild').html(stopTimeBuild);
            $('#startTimeBuildNext').html(startTimeBuildNext);
        });

        contract.getFreeTokenPerFloor(currHouse, function (error, dataGetFreeTokenPerFloor) {
            console.log("getFreeTokenPerFloor = " + JSON.stringify(dataGetFreeTokenPerFloor));
            var freeTokenPerFloor = dataGetFreeTokenPerFloor;
            $('#freeTokenPerFloor').html(freeTokenPerFloor);
        });

        contract.getFreeTokenNextFloor(currHouse, function (error, dataGetFreeTokenNextFloor) {
            console.log("getFreeTokenNextFloor = " + JSON.stringify(dataGetFreeTokenNextFloor));
            var freeTokenNextFloor = dataGetFreeTokenNextFloor;
            $('#freeTokenNextFloor').html(freeTokenNextFloor);
        });

        $('#numberAllHouse').html(Number(currHouse-1));
    });

    contract.getAmountTokenLastDay( function (error, data) {
	    console.log("getAmountTokenLastDay = " + data);
	    var amountTokenLastDay = data;
        $('#amountTokenLastDay').html(amountTokenLastDay.toFixed(0));
    });

    contract.getAmountTokenLastDayIfLessTen( function (error, data) {
        console.log("getAmountTokenLastDayIfLessTen = " + data);
        var amountTokenLastDayIfLessTen = data;
        $('#amountTokenLastDayIfLessTen').html(amountTokenLastDayIfLessTen.toFixed(0));
    });

    contract.getPriceTokenNextHouse( function (error, data) {
        console.log("getPriceTokenNextHouse = " + data);
        var priceTokenNextHouse = data;
        $('#priceTokenNextHouse').html(priceTokenNextHouse.toFixed(0));
    });

    contract.totalTokenRaised( function (error, data) {
        console.log("totalTokenRaised = " + data);
        var totalTokenRaised = data;
        $('#totalTokenRaised').html(totalTokenRaised.toFixed(0));
    });

    contract.totalEthRaised( function (error, data) {
        console.log("totalEthRaised = " + data);
        var totalEthRaised = data;
        $('#totalEthRaised').html(totalEthRaised.toFixed(0));
    });

    contract.totalFloorBuilded( function (error, data) {
        console.log("totalFloorBuilded = " + data);
        var totalFloorBuilded = data;
        $('#totalFloorBuilded').html(totalFloorBuilded.toFixed(0));
    });

    contract.totalPrize( function (error, data) {
        console.log("totalPrize = " + data);
        var totalPrize = data;
        $('#totalPrize').html(totalPrize.toFixed(0));
    });

    contract.tokenAllocated( function (error, data) {
        console.log("tokenAllocated = " + data);
        var tokenAllocated = data;
        $('#tokenAllocated').html(tokenAllocated.toFixed(0));
    });

    contract.investorMainInfo(myWalletAddress, function (error, data) {
        console.log("investorMainInfo = " + JSON.stringify(data));

        var investmentEth = data.investmentEth / decimal;
        $('#investmentEth').html(investmentEth.toFixed(4));

        var refundEth = data.refundEth / decimal;
        $('#refundEth').html(refundEth.toFixed(4));

        var amountToken = data.amountToken;
        $('#amountToken').html(amountToken.toFixed(0));

        var numberHouse = data.numberHouse;
        $('#numberHouse').html(numberHouse.toFixed(0));

    });

}

$(document).ready(function () {
});

function saleMyTokens() {
    console.log("sale tokens ...");
    var myWalletAddress = web3.eth.accounts[0];
    console.log("myWalletAddress = " + myWalletAddress);
    var saleEth = Number(0.0001) * decimal;
    contract.saleTokens(myWalletAddress, {from: web3.eth.accounts[0], value: saleEth}, function (error, data) {
    });
}

function buyMyTokens() {
    console.log("buy tokens ...");
    var myWalletAddress = web3.eth.accounts[0];
	console.log("myWalletAddress = " + myWalletAddress);
    var receiveEth = Number($('#investment').val()) * decimal;
    contract.buyTokens(myWalletAddress, {from: web3.eth.accounts[0], value: receiveEth}, function (error, data) {
    });

}

function initContract() {
    var address = {
        "1": adrressContractMain,
        "3": adrressContractRopsten
    }
    var current_network = web3.version.network;
    var myWalletAddress = web3.eth.accounts[0];
    if (myWalletAddress == undefined) {
        console.log("Your wallet is closed!");
    }
    $('#walletAddress').html(myWalletAddress);

    var abiContract = [{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"rate","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"INITIAL_SUPPLY","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"countClaimsToken","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_currentTime","type":"uint256"}],"name":"validPurchaseTime","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newRate","type":"uint256"}],"name":"setRate","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"claim","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_subtractedValue","type":"uint256"}],"name":"decreaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"tokenAllocated","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_weiAmount","type":"uint256"}],"name":"buyTokensFromContract","outputs":[{"name":"","type":"uint256"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_token","type":"address"}],"name":"claimTokensToOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"changeOwner","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_beneficiar","type":"address"}],"name":"calcAmount","outputs":[{"name":"amount","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"contractUsers","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"},{"name":"_data","type":"bytes"}],"name":"transfer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"transfersEnabled","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_addedValue","type":"uint256"}],"name":"increaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_investor","type":"address"}],"name":"buyTokens","outputs":[{"name":"","type":"uint256"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"_transfersEnabled","type":"bool"}],"name":"enableTransfers","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_weiAmount","type":"uint256"}],"name":"validPurchaseTokens","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"_owner","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"previousOwner","type":"address"},{"indexed":true,"name":"newOwner","type":"address"}],"name":"OwnerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"beneficiary","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"TokenPurchase","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"tokenRaised","type":"uint256"},{"indexed":false,"name":"purchasedToken","type":"uint256"}],"name":"TokenLimitReached","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"weiAmount","type":"uint256"}],"name":"MinWeiLimitReached","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"data","type":"bytes"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}];

    var contract = web3.eth.contract(abiContract).at(address[current_network]);
    console.log("Contract initialized successfully");
    console.log("current_network = " + current_network);
    console.log("myWalletAddress = " + myWalletAddress);

    return contract;
}

function resetting() {
    location.reload();
}

