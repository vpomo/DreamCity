const DreamCity = artifacts.require('./DreamCity.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0xC6209690b79DDB25d12EE7eD659B705eB6607879";
    var ownerTwo =  "0x0c12e6D170048651779aE496D9eD7B9F5149699A";
    var administrationWallet = "0xA06A5f58D9cD4292Bcba99996aCD3f56d9C0BB66";

    deployer.deploy(DreamCity, owner, ownerTwo, administrationWallet);0xA06A5f58D9cD4292Bcba99996aCD3f56d9C0BB66
};

//"0xC6209690b79DDB25d12EE7eD659B705eB6607879","0x0c12e6D170048651779aE496D9eD7B9F5149699A","0xA06A5f58D9cD4292Bcba99996aCD3f56d9C0BB66"

//list admin 0xd07954ec829655cd19da6315274fA799BacF7984