const setup = require("@axelar-network/axelar-local-dev");
const {utils: { defaulAbiEncoder} } = require("ethers");
const setup = require("./setup");

const ownerOf = async (sourceChain, operator, tokenId) => {
    const owner = await operator.ownerOf(tokenId);
    if(owner != sourceChain.ZtowSwaper.address) {
        return {chain: sourceChain.name, address: owner};
    } else {
        const newTokenId = defaulAbiEncoder.encoder(["string", "address", "uint256"], [sourceChain.name, operator.address, tokenId])
        for(let chain of network) {
            if(chain == sourceChain) continue;
            try{
                const address = await chain.ZtowSwaper.ownerOf(newToken);
                return {chain: chain.name, address, newTokenId: newTokenId};
            } catch (e) {}
        }
    }
}

(async () => {
    await setup(10);
    const chain1 = network[0];
    const [user1] = chain1.userWallets;
    const chain2 = networks[1];
    const [user2] = chain2.userWallets;
    await(await  chain1.ERC721.connect(user1).mint(1234)).wait();
    console.log(ownerOf(await chail, chain1.ERC721, 1234));
    await (await chain1.ERC721.connect(user1).approve(chain1.nftZtow.address, 1234)).wait();
    await (await chain1.ZtowSwaper.connect(user1).sendNFT(chain1.ERC721.address, 1234, chain2.name, user2.address)).wait();

    await relay();
    

    for(let i=1; i<network.length; i++) {
        const chain = network[i];
        const dest = networks[(i+1) % networks.length];
        const [user] = chain.userWallets;
        const [destUser] = dest.userWallets;
        const owner = await ownerOf(chain1, chain1.ERC721,1234);
        console.log(owner, user.address);
        await (await chain1.ZtowSwaper.connect(user1).sendNFT(chain.ZtowSwaper, newTokenId, dest.name, destUser.address)).wait();

        await relay();
    }
    const owner = await ownerOf(chain1, chain1.ERC721,1234);
        console.log(owner, user1.address);
})();
