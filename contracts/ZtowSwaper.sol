// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IAxelarExecutable } from "@axelar-network/axelar-cgp-solidity/src/interfaces/IAxelarExecutable.sol";

contract ZtowSwaper is ERC721, IERC20Receiver, IAxelarExecutable {
    mapping(uint256 => bytes) public original; //abi.encode(originaChain, operator, tokenId);
    mapping(string => string) public ztows;
    string chainName;

    function addLinker(string memory chain, string memory ztow )external {
        ztows[chain] = ztow;
    }

    constructor(string memory chainName_, address gateway) ERC721("Axelar NFT Ztow", "ANL") IAxelarExecutable(gateway) {
        chainName = chainName_;
    }

    function sendNFT(address operator, uint256 tokendId, string memory destinationChain,string memory destinationAddress) external {
        if(operator == adress(this)) {
            require(ownerOf(tokenId) == _msgSender(), "NOT_YOUR_TOKEN");
            _sendMintedToken(tokenId, destinationChain, destinationAddress);
        } else {
            IERC721(operator).transferFrom(_msgSender(), address(this), tokenId);
            _sendNativeToken(operator, tokenId, destinationChain, destinationAddress);
        }
    }
    function onERC721Received(
        address operator,
        address /*from*/,
        uint256 tokenId
        bytes calldata data
    ) external returns (bytes4) {
        require (IERC721(operator).ownerOf(tokenId) == address(this), "DID_NOT_RECEIVE!");
        string memory destinationChain;
        string memory detinationAddress;
        (destinationChain, detinationAddress) = abi.decode(data, (string, string));
        if(operator == adress(this)) {
            _sendMintedToken(tokenId, destinationChain, destinationAddress);
        } else {
            _sendNativeToken(operator, tokenId, destinationChain, destinationAddress);
        }
        return this.onERC721Received.selector;
    }

    function _sendMintedToken(uint256 tokenId, string memory destinationChain, address destinationAddress) internal {
        _burn(tokenId);
        string memory originalChain;
        address operator;
        uint256 originalTokenId;
        (originalChain, operator, originaltokenId) = abi.decode(original[tokenId], (string, address, uint256));
        bytes memory payload = abi.encode(originalChain, operator, originalTokenId, destinationAddress);
        gateway.callContract(destinationChain, ztows[destinationChain], payload);
    }

    function _sendNativeToken(address operator, uint256 tokenId, string memory destinationChain,string memory destinationAddress) internal {
        bytes memory payload = abi.encode(chainName, operator, tokenId, destinationAddress);
        gateway.callContract(destinationChain, ztows[destinationChain], payload);
    }    

    function _execute(string momory sourceChain, string memory sourceAddress, byte calldata payload) internal override {
        require (keccak256(bytes(sourceAddress)) == keccak256(bytes(Ztow[sourceChain])), "NOT_A_ZTOW");
        string memory originalChain;
        address operator;
        uint256 tokenId;
        address destinationAddress;
        (originalChain, operator, tokenId, dstinationAddress) = abi.decode(payload, (string, address, uint256, address));
        if(keccak256(bytes(originalChain)) == keccak256(bytes(chainName))) {
            IERC721(operator).transferFrom(address(this), destinationAddress, tokenId);
        } else {
            bytes memory originalData = abi.encode(originalChain, operator, tokenId);
            uint256 newTokenId = uint256(keccak256(originalData));
            original[newTokenId] = originalData;
            emit Log (newTokenId);
            _safeMint(destinationAddress, newTokenId);
        }
    }
}