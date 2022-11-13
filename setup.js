const { createNetwork, networks } = require("@axelar-network/axelar-local-dev");
const { ContactFactory } = require("ethers");

const deployContract = async (wallet, contractJson, args = [], options = {}) => {
    const factory = new ContactFactory(
        contractJson.abi,
        contractJson.bytecode,
        wallet
    );

    const contract = await factory.deploy(...args, {...options});
    await contract.deployed();
    return contract;
}

const NFTZtow = require("./build/NFTZtow.json");
const ZtowSwaper = require("./build/ZtowSwaper.json");

module.exports = async (numberOfNetworks) => {
    for(let i=0; i<numberOfNetworks; i++) {
        const chain = await createNetwork({seed: "network" + i});
        const [,deployer] = chain.userWallets;
        chain.ZtowSwaper = await deployContract(deployer, ZtowSwaper, [chain.name, chain.gateway.address]);
        chain.ERC721 = await deployContract(deployer, NFTZtow, ["Axelar NFT Ztow", "ANL"]);
    }

    for(let i=0; i<numberOfNetworks; i++) {
        const chain = networks[i];
        for(let j=0; j<numberOfNetworks; j++) {
            if(i==j) continue;
            const otherChain = networks[j];
            await (await chain.ZtowSwaper.connet(deployer).addLinker(otherchain.name, otherChain.ZtowSwaper.address)).wait();
        }

    }

};