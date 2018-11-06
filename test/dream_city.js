var DreamCity = artifacts.require("./DreamCity.sol");
//import assertRevert from './helpers/assertRevert';


contract('DreamCity', (accounts) => {
    var contract;
    var owner = accounts[0]; // for test

    it('should deployed contract', async ()  => {
        assert.equal(undefined, contract);
        contract = await DreamCity.deployed();
        assert.notEqual(undefined, contract);
    });

    it('get address contract', async ()  => {
        assert.notEqual(undefined, contract.address);
    });

});



