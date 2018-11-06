var DreamCity = artifacts.require("./DreamCity.sol");
//import assertRevert from './helpers/assertRevert';


contract('DreamCity', (accounts) => {
    var contract;
    var owner = accounts[0]; // for test
    var buyEth = 6e17;

    it('should deployed contract', async ()  => {
        assert.equal(undefined, contract);
        contract = await DreamCity.deployed();
        assert.notEqual(undefined, contract);
    });

    it('get address contract', async ()  => {
        assert.notEqual(undefined, contract.address);
    });

    it('verify by tokens', async ()  => {
        await contract.buyTokens(accounts[1], {from:accounts[1], value: buyEth});
        var mainInfoInvestor = await contract.investorMainInfo.call(accounts[1]);
        console.log("mainInfoInvestor", JSON.stringify(mainInfoInvestor));
        console.log("mainInfoInvestor.investmentEth", Number(mainInfoInvestor.investmentEth));
        console.log("mainInfoInvestor.amountToken", Number(mainInfoInvestor.amountToken));
    });

});



