const DreamCity = artifacts.require('./DreamCity.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";
    var ownerTwo =  "0x0c12e6D170048651779aE496D9eD7B9F5149699A";
    var administrationWallet = "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";
    var wallet = "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";

    deployer.deploy(DreamCity, owner, ownerTwo, administrationWallet, wallet);
};

//"0xC6209690b79DDB25d12EE7eD659B705eB6607879","0x0c12e6D170048651779aE496D9eD7B9F5149699A","0xA06A5f58D9cD4292Bcba99996aCD3f56d9C0BB66","0xf5F1b7bf5B27588E3d6C8fD9065ed60BA12fc755"

//Надо в simulate day ставить более позднюю дату
