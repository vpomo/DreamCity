const DreamCity = artifacts.require('./DreamCity.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";
    var administrationWallet = "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";
    var wallet = "0xb10Dc0448571f33d0Fe695760eCfA6378224e8Aa";

    deployer.deploy(DreamCity, owner, administrationWallet, wallet);
};

//"0xC6209690b79DDB25d12EE7eD659B705eB6607879","0xA06A5f58D9cD4292Bcba99996aCD3f56d9C0BB66","0xf5F1b7bf5B27588E3d6C8fD9065ed60BA12fc755"