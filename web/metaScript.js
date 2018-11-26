var adrressContractRopsten = "0x8fcb31762f589dab445a2305bdee82bd53938e58";
var adrressContractMain = "0xe4a60882c473e008b4e1c942bd73addf50483825";
var contract;
var SECUND_TO_DAY = 86400;
var EMPTY_VALUE = "---";

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

    contract.currentHouse.call( function (error, data) {
        var currHouse = data;
        console.log("currentHouse = " + currHouse);
        contract.houseInfo(currHouse, function (error, dataHouse) {
            var houseInfo = dataHouse;
            console.log("houseInfo = " + JSON.stringify(houseInfo));

            var priceToken = houseInfo[2] / decimal;
            var paymentTokenTotal = houseInfo[1];
            contract.stopBuyTokens( function (error, data) {
                var stopBuyTokens = data;
                if (stopBuyTokens == true) {
                    $('#priceToken').html(EMPTY_VALUE);
                    $('#paymentTokenTotal').html(EMPTY_VALUE);
				} else {
                    $('#priceToken').html(priceToken.toFixed(4));
                    $('#paymentTokenTotal').html(paymentTokenTotal.toFixed(0));
				}
            });

            var totalEth = houseInfo[4] / decimal;
            $('#totalEth').html(totalEth.toFixed(4));
			
			var totalPrizeLastInvestor = (totalEth * 1.1) / 100;
			$('#totalPrizeLastInvestor').html(totalPrizeLastInvestor.toFixed(4));
            console.log("totalPrizeLastInvestor = " + totalPrizeLastInvestor.toFixed(4));

            var totalPrizeAllInvestor = (totalEth * 2) / 100;
            $('#totalPrizeAllInvestor').html(totalPrizeAllInvestor.toFixed(4));
            console.log("totalPrizeAllInvestor = " + totalPrizeAllInvestor.toFixed(4));

            var priceTokenNextHouse = totalEth / paymentTokenTotal;

            contract.houseTimeInfo(currHouse, function (error, dataTimeInfo) {
                console.log("houseTimeInfo = " + JSON.stringify(dataTimeInfo));
                console.log("Math.trunc(dataTimeInfo[0]) = " + Math.trunc(dataTimeInfo[0]/SECUND_TO_DAY));
                var numberDayStopBuild = Math.trunc(dataTimeInfo[0]/SECUND_TO_DAY);
                //numberDayStopBuild += 2;

                var startTimeBuild = timeConverter(Math.trunc(dataTimeInfo[0]/SECUND_TO_DAY)*SECUND_TO_DAY);

                var stopTimeBuild;
                var startTimeBuildNext;

                var lastFloor = Number(houseInfo[3]) + 1;
                var priceTokenNext = priceToken * 1.05;
                var stopTimeBuildUnix = dataTimeInfo[1];

                if (stopTimeBuildUnix == 0) {
                    contract.stopBuyTokens( function (error, data) {
                    	var stopBuyTokens = data;
                        console.log("stopBuyTokens = " + stopBuyTokens);
                        if (stopBuyTokens == true) {
                            contract.houseTimeInfo(currHouse-1, function (error, dataTimeInfo) {
                                console.log("houseTimeInfo = " + JSON.stringify(dataTimeInfo));
                                stopTimeBuild = timeConverter(dataTimeInfo[1]);
                                var numberDayStopBuild = Math.trunc(dataTimeInfo[0]/SECUND_TO_DAY);
                                numberDayStopBuild += 2;
                                startTimeBuildNext = timeConverter(Number(numberDayStopBuild)*SECUND_TO_DAY + Number(60));
                                $('#priceTokenNextHouse').html(priceToken.toFixed(4));
                                $('#numberAllHouse').html(Number(currHouse-1));
                                $('#lastFloor').html(EMPTY_VALUE);
                                $('#priceTokenNext').html(EMPTY_VALUE);

                                $('#stopTimeBuild').html(stopTimeBuild);
                                $('#startTimeBuildNext').html(startTimeBuildNext);
                            });

                    	} else {
                            stopTimeBuild = EMPTY_VALUE;
                            startTimeBuildNext = EMPTY_VALUE;
                            $('#priceTokenNextHouse').html(EMPTY_VALUE);
                            $('#numberAllHouse').html(Number(currHouse-1));
                            $('#lastFloor').html(lastFloor);
                            $('#priceTokenNext').html(priceTokenNext.toFixed(4));
						}
                    });

                } else {
                    stopTimeBuild = timeConverter(dataTimeInfo[1]);
                    startTimeBuildNext = timeConverter(numberDayStopBuild*SECUND_TO_DAY + Number(60));
                    $('#priceTokenNextHouse').html(priceTokenNextHouse.toFixed(4));
                    $('#numberAllHouse').html(Number(currHouse));
                    $('#lastFloor').html(EMPTY_VALUE);
                    $('#priceTokenNext').html(EMPTY_VALUE);
                }

                $('#startTimeBuild').html(startTimeBuild);
                $('#stopTimeBuild').html(stopTimeBuild);
                $('#startTimeBuildNext').html(startTimeBuildNext);

                contract.getFreeTokenPerFloor(currHouse, function (error, dataGetFreeTokenPerFloor) {
                    console.log("getFreeTokenPerFloor = " + JSON.stringify(dataGetFreeTokenPerFloor));
                    var freeTokenPerFloor = dataGetFreeTokenPerFloor;
                    if (stopTimeBuildUnix == 0) {
                        $('#freeTokenPerFloor').html(freeTokenPerFloor.toFixed(0));
					} else {
                        $('#freeTokenPerFloor').html(EMPTY_VALUE);
                    }
                });

                contract.getFreeTokenNextFloor(function (error, dataGetFreeTokenNextFloor) {
                    console.log("getFreeTokenNextFloor = " + JSON.stringify(dataGetFreeTokenNextFloor));
                    var freeTokenNextFloor = dataGetFreeTokenNextFloor;
                    if (stopTimeBuildUnix == 0) {
                        contract.stopBuyTokens( function (error, data) {
                            var stopBuyTokens = data;
                            if (stopBuyTokens == true) {
                                $('#freeTokenNextFloor').html(EMPTY_VALUE);
                            } else {
                                $('#freeTokenNextFloor').html(freeTokenNextFloor.toFixed(0));
                            }
                        });
                    } else {
                        $('#freeTokenNextFloor').html(EMPTY_VALUE);
                    }
                });
            });

            contract.getAmountTokenLastDayIfLessTen( function (error, data) {
                console.log("getAmountTokenLastDayIfLessTen = " + data);
                var amountTokenLastDayIfLessTen = data;
                $('#amountTokenLastDayIfLessTen').html(amountTokenLastDayIfLessTen.toFixed(0));
            });

        });

    });

    contract.getAmountTokenLastDay( function (error, data) {
	    console.log("getAmountTokenLastDay = " + data);
	    var amountTokenLastDay = data;
        $('#amountTokenLastDay').html(amountTokenLastDay.toFixed(0));
    });

/*
    contract.getPriceTokenNextHouse( function (error, data) {
        console.log("getPriceTokenNextHouse = " + data);
        var priceTokenNextHouse = data;
        $('#priceTokenNextHouse').html(priceTokenNextHouse.toFixed(0));
    });
*/

    contract.investorMainInfo(myWalletAddress, function (error, data) {
        console.log("investorMainInfo = " + JSON.stringify(data));

        var investmentEth = data[0] / decimal;
        $('#investmentEth').html(investmentEth.toFixed(4));

        var refundEth = data[1] / decimal;
        $('#refundEth').html(refundEth.toFixed(4));

        var amountToken = data[2];
        $('#amountToken').html(amountToken.toFixed(0));

        var numberHouse = data[3];
        $('#numberHouse').html(numberHouse.toFixed(0));

    });

    contract.totalTokenRaised.call( function (error, data) {
        console.log("totalTokenRaised = " + data);
        var totalTokenRaised = data;
        $('#totalTokenRaised').html(totalTokenRaised.toFixed(0));
    });

    contract.totalEthRaised.call( function (error, data) {
        console.log("totalEthRaised = " + data);
        var totalEthRaised = data / decimal;
        $('#totalEthRaised').html(totalEthRaised.toFixed(4));
    });

    contract.totalFloorBuilded.call( function (error, data) {
        console.log("totalFloorBuilded = " + data);
        var totalFloorBuilded = data;
        $('#totalFloorBuilded').html(totalFloorBuilded.toFixed(0));
    });

//    contract.totalPrize.call( function (error, data) {
//        console.log("totalPrize = " + data);
        //var totalPrize = data;
//        $('#totalPrize').html(totalPrize.toFixed(0));
    //});

    contract.tokenAllocated.call( function (error, data) {
        console.log("tokenAllocated = " + data);
        var tokenAllocated = data;
        $('#tokenAllocated').html(tokenAllocated.toFixed(0));
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

function simulateDate() {
    console.log("simulateDate ...");
    var simulateDate = $('#simulateDate').val();
    contract.setSimulateDate(simulateDate, function (error, data) {
    });

}

function timeConverter(UNIX_timestamp){
    var a = new Date(UNIX_timestamp * 1000);
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time = date + ' ' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec ;
    return time;
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

    var abiContract = [
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_admin",
                    "type": "address"
                }
            ],
            "name": "addToAdminlist",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_investor",
                    "type": "address"
                }
            ],
            "name": "buyTokens",
            "outputs": [
                {
                    "name": "tokens",
                    "type": "uint256"
                }
            ],
            "payable": true,
            "stateMutability": "payable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_newOwner",
                    "type": "address"
                }
            ],
            "name": "changeOwner",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_date",
                    "type": "uint256"
                }
            ],
            "name": "checkStopBuyTokens",
            "outputs": [
                {
                    "name": "",
                    "type": "bool"
                }
            ],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_amountEth",
                    "type": "uint256"
                }
            ],
            "name": "getBuyToken",
            "outputs": [
                {
                    "name": "totalTokens",
                    "type": "uint256"
                },
                {
                    "name": "remainEth",
                    "type": "uint256"
                },
                {
                    "name": "lastFloorPerHouse",
                    "type": "bool"
                }
            ],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_amountEth",
                    "type": "uint256"
                }
            ],
            "name": "getBuyTokenAdmin",
            "outputs": [
                {
                    "name": "totalTokens",
                    "type": "uint256"
                },
                {
                    "name": "remainEth",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_admin",
                    "type": "address"
                }
            ],
            "name": "removeFromAdminlist",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_investor",
                    "type": "address"
                }
            ],
            "name": "saleTokens",
            "outputs": [],
            "payable": true,
            "stateMutability": "payable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_status",
                    "type": "bool"
                }
            ],
            "name": "setDemo",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_newDate",
                    "type": "uint256"
                }
            ],
            "name": "setSimulateDate",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "_newDate",
                    "type": "uint256"
                }
            ],
            "name": "setStartDate",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "name": "_owner",
                    "type": "address"
                },
                {
                    "name": "_administrationWallet",
                    "type": "address"
                },
                {
                    "name": "_wallet",
                    "type": "address"
                }
            ],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "payable": true,
            "stateMutability": "payable",
            "type": "fallback"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "beneficiary",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "name": "value",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "amount",
                    "type": "uint256"
                }
            ],
            "name": "TotalTokenPurchase",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "sender",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "name": "tokenRaised",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "purchasedToken",
                    "type": "uint256"
                }
            ],
            "name": "TokenLimitReached",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "name": "period",
                    "type": "uint256"
                }
            ],
            "name": "CurrentPeriod",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "investor",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "name": "value",
                    "type": "uint256"
                }
            ],
            "name": "RefundEth",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "name": "date",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "numberFloor",
                    "type": "uint256"
                }
            ],
            "name": "NextFloor",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "investor",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "name": "date",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "priceToken",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "amountEth",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "amountToken",
                    "type": "uint256"
                }
            ],
            "name": "TokenSale",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "name": "date",
                    "type": "uint256"
                }
            ],
            "name": "StopBuyTokens",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "investor",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "name": "paymentTime",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "amountEth",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "amountToken",
                    "type": "uint256"
                }
            ],
            "name": "TokenPurchaise",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "name": "_newDate",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "name": "simulateDate",
                    "type": "uint256"
                }
            ],
            "name": "ChangeTime",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "name": "previousOwner",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "name": "newOwner",
                    "type": "address"
                }
            ],
            "name": "OwnerChanged",
            "type": "event"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "administrationWallet",
            "outputs": [
                {
                    "name": "",
                    "type": "address"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "averagePriceToken",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_amountEth",
                    "type": "uint256"
                }
            ],
            "name": "checkBuyTokenPerFloor",
            "outputs": [
                {
                    "name": "tokens",
                    "type": "uint256"
                },
                {
                    "name": "needEth",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "countInvestors",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "currentHouse",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getAmountTokenLastDay",
            "outputs": [
                {
                    "name": "amountTokenLastDay",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getAmountTokenLastDayIfLessTen",
            "outputs": [
                {
                    "name": "amountTokenLastDayIfLessTen",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getCurrentDate",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_amountToken",
                    "type": "uint256"
                },
                {
                    "name": "_amountEth",
                    "type": "uint256"
                },
                {
                    "name": "_priceToken",
                    "type": "uint256"
                }
            ],
            "name": "getDifferentEth",
            "outputs": [
                {
                    "name": "result",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "pure",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getFreeTokenNextFloor",
            "outputs": [
                {
                    "name": "tokens",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberHouse",
                    "type": "uint256"
                }
            ],
            "name": "getFreeTokenPerFloor",
            "outputs": [
                {
                    "name": "tokens",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "index",
                    "type": "uint256"
                }
            ],
            "name": "getMemberArrayPaidTokenLastDay",
            "outputs": [
                {
                    "name": "investor",
                    "type": "address"
                },
                {
                    "name": "amountToken",
                    "type": "uint256"
                },
                {
                    "name": "paymentTime",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_date",
                    "type": "uint256"
                }
            ],
            "name": "getNumberDay",
            "outputs": [
                {
                    "name": "result",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "pure",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberDay",
                    "type": "uint256"
                }
            ],
            "name": "getPaidPerDay",
            "outputs": [
                {
                    "name": "result",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getPriceTokenNextHouse",
            "outputs": [
                {
                    "name": "result",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "getTimeLastInvestor",
            "outputs": [
                {
                    "name": "lastTimePaid",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberHouse",
                    "type": "uint256"
                }
            ],
            "name": "getTotalEthPerHouse",
            "outputs": [
                {
                    "name": "eths",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberHouse",
                    "type": "uint256"
                }
            ],
            "name": "getTotalTokenPerHouse",
            "outputs": [
                {
                    "name": "tokens",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberHouse",
                    "type": "uint256"
                }
            ],
            "name": "houseInfo",
            "outputs": [
                {
                    "name": "paymentTokenPerFloor",
                    "type": "uint256"
                },
                {
                    "name": "paymentTokenTotal",
                    "type": "uint256"
                },
                {
                    "name": "priceToken",
                    "type": "uint256"
                },
                {
                    "name": "lastFloor",
                    "type": "uint256"
                },
                {
                    "name": "totalEth",
                    "type": "uint256"
                },
                {
                    "name": "refundEth",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_numberHouse",
                    "type": "uint256"
                }
            ],
            "name": "houseTimeInfo",
            "outputs": [
                {
                    "name": "startTimeBuild",
                    "type": "uint256"
                },
                {
                    "name": "stopTimeBuild",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_investor",
                    "type": "address"
                }
            ],
            "name": "investorMainInfo",
            "outputs": [
                {
                    "name": "investmentEth",
                    "type": "uint256"
                },
                {
                    "name": "refundEth",
                    "type": "uint256"
                },
                {
                    "name": "amountToken",
                    "type": "uint256"
                },
                {
                    "name": "numberHouse",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_investor",
                    "type": "address"
                }
            ],
            "name": "investorTimeInfo",
            "outputs": [
                {
                    "name": "paymentTime",
                    "type": "uint256"
                },
                {
                    "name": "sellTime",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "isDemo",
            "outputs": [
                {
                    "name": "",
                    "type": "bool"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "_date",
                    "type": "uint256"
                }
            ],
            "name": "isOneDay",
            "outputs": [
                {
                    "name": "result",
                    "type": "bool"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "numberTokensPerFloor",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "owner",
            "outputs": [
                {
                    "name": "",
                    "type": "address"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "paidPerDay",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "simulateDate",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "startTime",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "stopBuyTokens",
            "outputs": [
                {
                    "name": "",
                    "type": "bool"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "tokenAllocated",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalEthPerHouse",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalEthRaised",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalFloorBuilded",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalPrize",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalRefundEth",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "totalTokenRaised",
            "outputs": [
                {
                    "name": "",
                    "type": "uint256"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [],
            "name": "wallet",
            "outputs": [
                {
                    "name": "",
                    "type": "address"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        }
    ];

    var contract = web3.eth.contract(abiContract).at(address[current_network]);
    console.log("Contract initialized successfully");
    console.log("current_network = " + current_network);
    console.log("myWalletAddress = " + myWalletAddress);

    return contract;
}

function resetting() {
    location.reload();
}

