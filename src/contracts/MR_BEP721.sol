// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at elsilver.net on 2021-11-05
*/
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MR_BEP721 is Context, ERC165, IERC721, Ownable{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for bool;
    using Counters for Counters.Counter;
    
    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    // Map the number of tokens per mrId
    mapping(uint8 => uint256) public mrCount;
    
    // Map the number of tokens burnt per mrId
    mapping(uint8 => uint256) public mrBurnCount;

    // Used for generating the tokenId of new NFT minted
    Counters.Counter private _tokenIds;
    
    // Map the mrId for each tokenId
    mapping(uint256 => uint8) private mrIds;

    // Used for generating the itemId of new NFT Item created
    Counters.Counter private _mrIdKindCount;
    
    // nft mr item struct
    struct MRinfo{
        // nft item Id
        uint8 mrId;
        // nft item name
        string mrName;
        // nft item rate
        uint256 mrRate;
        // nft item price
        uint256 mrPrice;
        // nft item image URI
        string mrMetaDataURI;
        // nft item image thumnail URI
        uint256 maxCount;
    }
    // Map the nft mr item info for mrID
    mapping(uint8 => MRinfo) private mrInfos;
    
    // Map the owned nft mr item price for each tokenId
    mapping(uint256 => uint256) private ownedNftPrice;
    // Map the owned nft mr item sell state for each tokenId. 1: sell, 0: keep
    mapping(uint256=>uint8) private ownedNftState;
    constructor () {
        _name = "Mining Rights Token";
        _symbol = "MRT";
        _baseURI = "https://gateway.pinata.cloud/ipfs/QmZXjedLkAeCzUzYQ7EMoPLtn82qVeWXB8PvvatPbmXqiq/";
    }

    // Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    //Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    //Returns the token collection name.
    function name() public view returns (string memory) {
        return _name;
    }

    //Returns the token collection symbol.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    //Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    //Returns the base URI set via {_setBaseURI}. This will be
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    //Returns a token ID owned by `owner` at a given `index` of its token list.
    //Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    //Returns the total amount of tokens stored by the contract.
    function totalSupply() public view returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    //Returns a token ID at a given `index` of all the tokens stored by the contract.
    //Use along with {totalSupply} to enumerate all tokens.
    function tokenByIndex(uint256 index) public view returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /*Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(_exists(tokenId), "nonexistent token");
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    //dev Returns the account approved for `tokenId` token.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /*Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * - The `operator` cannot be the caller.
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    //Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        
        
    }
    function safeTransferFrom2(address from, address to, uint256 tokenId) public payable {
        require(_exists(tokenId), "nonexistent token");
        require(msg.value == ownedNftPrice[tokenId], "input the exact price.");
        require(ownedNftState[tokenId] == 1);
        safeTransferFrom2(from, to, tokenId, "");
        ownedNftState[tokenId] = 0;
    }

    /* @dev Safely transfers `tokenId` token from `from` to `to`.
       - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    }
    function safeTransferFrom2(address from, address to, uint256 tokenId, bytes memory _data) internal {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * Requirements:
     * - `tokenId` must exist.
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * Requirements:
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * Requirements:
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == IERC721Receiver.onERC721Received.selector);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    
    /**
     * @dev Get mrId for a specific tokenId.
     */
    function getMrId(uint256 _tokenId) public view returns (uint8) {
        require(_exists(_tokenId), "nonexistent token");
        
        return mrIds[_tokenId];
    }

    /**
     * @dev Get the associated mrName for a specific mrId.
     */
    function getMrName(uint8 _mrId) public view returns (string memory){
        return mrInfos[_mrId].mrName;
    }
    
     /**
     * @dev Get the associated rate for a specific mrId.
     */
    function getMrRate(uint8 _mrId) public view returns (uint256){
        return mrInfos[_mrId].mrRate;
    }
    
    /**
     * @dev Get the associated price for a specific mrId.
     */
    function getMrPrice(uint8 _mrId) public view returns (uint256){
        return mrInfos[_mrId].mrPrice;
    }

    /**
     * @dev Get the associated mrName for a unique tokenId.
     */
    function getMrNameOfTokenId(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "nonexistent token");
        return mrInfos[mrIds[_tokenId]].mrName;
    }

    /**
     * @dev Mint NFTs. Only the owner can call it.
     */
    function mintToken(address _to, uint8 _mrId, uint256 _count) public payable{    
        
        require(_count >0);
        require((mrCount[_mrId] + _count) <= mrInfos[_mrId].maxCount, "exceeded the maximum number of purchases.");
        require(msg.value == mrInfos[_mrId].mrPrice * _count, "input the exact price.");
        
        uint256 i;
        uint256 newId;
        for(i = 0; i < _count; i++)
        {
        
             newId = _tokenIds.current();
            _tokenIds.increment();
            mrIds[newId] = _mrId;
            
            mrCount[_mrId] = mrCount[_mrId].add(1);
            
            _mint(_to, newId);
            
            _setTokenURI(newId, mrInfos[_mrId].mrMetaDataURI);
            
            ownedNftPrice[newId] = mrInfos[_mrId].mrPrice;
            
            ownedNftState[newId] = 0;
        }
    }
    
    /**
     * @dev create new NFT MR item. Only the owner can call it.
     */
    function mintMrId(string memory _mrName, uint256 _mrRate, uint256 _mrPrice, 
        string memory _mrMetaDataURI, uint256 _maxCount) public onlyOwner returns (uint8){
            
        require(_mrIdKindCount.current() < 256, "impossible to create a new kind of nft item any more.");
        uint8 newMrId = uint8(_mrIdKindCount.current());
        _mrIdKindCount.increment();
        
        MRinfo memory mrInfo;
        
        mrInfo = MRinfo(newMrId, _mrName, _mrRate, _mrPrice, _mrMetaDataURI, _maxCount);
        mrInfos[newMrId] = mrInfo;
        return newMrId;
    }
    
    function getMrItemKindCount() public view returns (uint256){
        return _mrIdKindCount.current();
    }

    /**
     * @dev Set a unique name for each mrId. It is supposed to be called once.
     */
    function setMrName(uint8 mrId_, string memory name_) public onlyOwner {
        mrInfos[mrId_].mrName = name_;
    }
    
    /**
     * @dev Set a rate for each mrId. It is supposed to be called once.
     */
    function setMrRate(uint8 mrId_, uint256 _rate) public onlyOwner {
        mrInfos[mrId_].mrRate = _rate;
    }
    
    /**
     * @dev Set a price for each mrId. It is supposed to be called once.
     */
    function setMrPrice(uint8 mrId_, uint256 price_) public onlyOwner {
        mrInfos[mrId_].mrPrice = price_;
    }
    
    /**
     * @dev Set a MetaDataURI for each mrId. It is supposed to be called once.
     */
    function setMrMetaDataURI(uint8 mrId_, string memory _MetaData) public onlyOwner {
        mrInfos[mrId_].mrMetaDataURI = _MetaData;
    }
    /**
     * @dev Get a MetaDataURI for each mrId. It is supposed to be called once.
     */
    function getMrMetaDataURI(uint8 mrId_) public view returns (string memory) {
        string memory MetaData =mrInfos[mrId_].mrMetaDataURI;
        return MetaData;
    }
    /**
     * @dev Get a minted token count for each mrId. It is supposed to be called once.
     */
    function getMrMintedTokenCount(uint8 mrId_) public view returns (uint256) {
        return mrCount[mrId_];
    }
    
    /**
     * @dev Get a initial mintable max token count for each mrId. It is supposed to be called once.
     */
    function getMrMaxTokenCount(uint8 mrId_) public view returns (uint256) {
        return mrInfos[mrId_].maxCount;
    }
    
    /**
     * @dev Set a maxCount for each mrId. It is supposed to be called once.
     */
    function setMrMaxCount(uint8 mrId_, uint256 _maxCount) public onlyOwner {
        mrInfos[mrId_].maxCount = _maxCount;
    }
    
    /**
     * @dev Get a price for _tokenId. It is supposed to be called once.
     */
    function getUserMrPrice(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "nonexistent token");
        
        return ownedNftPrice[_tokenId];
    }
    /**
     * @dev Set a salable state for _tokenId. It is supposed to be called once. true: salable, false: not salable
     */
    function setUserNftSellState(uint256 _tokenId, uint256 _price, uint8 state) public {
        require(_exists(_tokenId), "nonexistent token");
        require(msg.sender == ownerOf(_tokenId));
        state = state % 2;
        ownedNftPrice[_tokenId] = _price;
        ownedNftState[_tokenId] = state;
    }
    /**
     * @dev Get a salable state for _tokenId. It is supposed to be called once. true: salable, false: not salable
     */
    function getUserNftSellState(uint256 _tokenId) public view returns (uint8){
        require(_exists(_tokenId), "nonexistent token");
        return ownedNftState[_tokenId];
    }
    
    function fetchUserInventory(address wallet) public view returns (string memory){
        uint256 ownedTokenCount = balanceOf(wallet);
        string memory json;
        uint256 tokenId;
        uint8 itemId;
        json = "[";
        
        for (uint256 i = 0; i < ownedTokenCount; i++){
            tokenId = tokenOfOwnerByIndex(wallet, i);
            itemId = getUserNftSellState(tokenId);
            json = string(abi.encodePacked(json, "{\"tokenId\":\"", tokenId.toString(), "\",\"tokenSellState\":\"", 
              getUserNftSellState(tokenId).toString(), "\",\"itemId\":\"", itemId.toString(), "\", \"price\":\"", getUserMrPrice(tokenId).toString(), 
              "\",\"metaDataURI\":\"", tokenURI(tokenId), "\"}"));
            if(i != ownedTokenCount-1)
                json = string(abi.encodePacked(json, ","));
            
        }
        json = string(abi.encodePacked(json, "]"));
        return json;
    }
    
    function fetchItemFromShop() public view returns (string memory){
        uint256 itemKindCount = getMrItemKindCount();
        string memory json;
        
        json = "[";
        for (uint8 i = 0; i < itemKindCount; i++){
            
            json = string(abi.encodePacked(json, "{\"mrId\":\"", mrInfos[i].mrId.toString(), "\", \"mrMetaDataURI\":\"", mrInfos[i].mrMetaDataURI, "\", \"mrPrice\":\"", mrInfos[i].mrPrice.toString(), 
              "\", \"maxCount\":\"", mrInfos[i].maxCount.toString(), "\"}"));
            if(i != itemKindCount-1)
              json = string(abi.encodePacked(json, ","));
            
        }
        json = string(abi.encodePacked(json, "]"));
        return json;
    }
    
    function fetchItemFromMarketPlace() public view returns (string memory){
        uint256 totalTokenCount = totalSupply();
        uint256 tokenId;
        string memory json;
        json = "[";
        for(uint256 i = 0; i < totalTokenCount; i++)
        {
            tokenId = tokenByIndex(i);
            if(getUserNftSellState(tokenId) == 1)
            {
                json = string(abi.encodePacked(json, "{\"tokenId\":\"", tokenId.toString(), "\", \"owner\":\"", 
                  ownerOf(tokenId), "\", \"price\":\"", getUserMrPrice(tokenId).toString(), "\", \"mrMetaDataURI\":\"", tokenURI(tokenId), 
                  "\", \"mrId\":\"", getMrId(tokenId).toString(), "\"}"));
                if(i != totalTokenCount-1)
                    json = string(abi.encodePacked(json, ","));
            }
        }
        json = string(abi.encodePacked(json, "]"));
        return json;
    }

    
    /**
     * @dev Burn a NFT token. Callable by owner only.
     */
    function burn(uint256 _tokenId) public onlyOwner {
        require(_exists(_tokenId), "nonexistent token");
        uint8 mrIdBurnt = mrIds[_tokenId];
        mrCount[mrIdBurnt] = mrCount[mrIdBurnt].sub(1);
        mrBurnCount[mrIdBurnt] = mrBurnCount[mrIdBurnt].add(1);
        _burn(_tokenId);
    }
}