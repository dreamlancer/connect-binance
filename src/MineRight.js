//import React from "react";
import { useEffect, useState } from "react";
import Web3 from "web3";
import { utils } from 'ethers'
import ShopCard from "./component/ShopCard";
import MarketCard from "./component/MarketCard";
import axios from "axios";
import Loader from 'react-loader-spinner';
import InventoryCard from "./component/InventoryCard";
require("dotenv").config();

const MineRight = () => {
  //state variables
  const [status, setStatus] = useState("");
  const [message, setMessage] = useState(""); //default message
  const [newMessage, setNewMessage] = useState("");
  const [baseURI, setBaseURI] = useState("");
  const [items, setItems] = useState([])
  const [inventories, setInventories] = useState([]);
  const [loading, setLoading] = useState(false)

  const [itemName, setItemName] = useState("");
  const [itemRate, setItemRate] = useState("");
  const [itemPrice, setItemPrice] = useState("");
  const [itemImageURI, setItemImageURI] = useState("");
  const [itemMaxCount, setItemMaxCount] = useState("");
  
  const [CHAIN_ID, setChainID] = useState(0)
  const [walletAddress, setWalletAddress] = useState('')
  const [BNB_balance, set_BNB_Balance] = useState(0)
  const [LPLT_Balance, set_LPLT_Balance] = useState(0)
  const [connected, setConnected] = useState(false)  
  const { REACT_APP_LPLT_BEP20_CONTRACT_ADDR, REACT_APP_MR_BEP721_CONTRACT_ADDR } = process.env;

  const bep20_contractABI = require("./contracts/bep20-contract-abi.json");
  const bep721_contractABI = require("./contracts/bep721-contract-abi.json")
  const Web3Modal = window.Web3Modal.default;
  const WalletConnectProvider = window.WalletConnectProvider.default;

  const itemList = [{id:0, name:"item1", rate:16.72, price:"0.001", imageURI:"./assets/1.jpg"},
    {id:1, name:"item1", rate:16.72, price:"0.001", imageURI:"./assets/2.jpg"},
    {id:2, name:"item1", rate:16.72, price:"0.001", imageURI:"./assets/3.jpg"},
    {id:3, name:"item1", rate:16.72, price:"0.001", imageURI:"./assets/4.jpg"}
  ];

  const [mintCount, setMintCount] = useState(0)

  useEffect(() => {

    const initWalletConnect = () => {

      const providerOptions = {
        disableInjectedProvider: true,
        injected: {
            display: {
                name: "MetaMask",
                description: "For desktop web wallets",
            },
            package: null,
        },
        walletconnect: {
            display: {
                name: "WalletConnect",
                description: "For mobile app wallets",
            },
            package: WalletConnectProvider,
            options: {
                infuraId: "40bd58898adb4907b225865d9cedcd4a",
            },
        },
      };

      let web3ModalObj = new Web3Modal({
        // network: "mainnet",
        cacheProvider: false,
        providerOptions,        
      });
      window.web3Modal = web3ModalObj
    }
    initWalletConnect();
  }, [WalletConnectProvider, Web3Modal])

  useEffect(() => {

  }, [])

  const fetchAccountData = async () => {
    const web3Obj = new Web3(window.provider);
    window.web3 = web3Obj;

    let chain_id = await web3Obj.eth.getChainId();
    
    if(chain_id === 97 || chain_id === 56) {
        const accounts = await web3Obj.eth.getAccounts();
        setChainID(chain_id);
        setWalletAddress(accounts[0])
        setConnected(true);
    
        connectContract(accounts[0]);
        
    } else {
      setConnected(false);
      alert("Please connect with Binance Smart Chain net");
    }
  }
  
  const getBEP20Contract = () => {    
    const contract = new window.web3.eth.Contract(bep20_contractABI, REACT_APP_LPLT_BEP20_CONTRACT_ADDR);
    return contract;
  }
  const getBEP721Contract = () => {    
    console.log(55, REACT_APP_MR_BEP721_CONTRACT_ADDR)
    const contract = new window.web3.eth.Contract(bep721_contractABI, REACT_APP_MR_BEP721_CONTRACT_ADDR);
    return contract;
  }
  // conneting wallet function
  const connectContract = async (accountID) => {    
    const userBNB_Balance = await Get_BNB_Balance(accountID);    
    set_BNB_Balance(userBNB_Balance);

    const userLPLT_Balance = await Get_LBLT_Balance(accountID);    
    set_LPLT_Balance(userLPLT_Balance)

    fetchUserInventory(accountID)
  }
  // getting BNB(accountID is wallet address)
  const Get_BNB_Balance = async (accountID) => {
    const userBNB_Balance = await window.web3.eth.getBalance(accountID); 
    let userBNB_BalanceString = await parseFloat(window.web3.utils.fromWei(userBNB_Balance, "ether")).toFixed(4).toString()   
    return userBNB_BalanceString;
  }
  // getting LPLT(accountID is wallet address)
  const Get_LBLT_Balance = async (accountID) => {
    const BEP20Contract = getBEP20Contract();
    let userLPLT_Balance = await BEP20Contract.methods.balanceOf(accountID).call()
    let userLPLT_BalanceString = await parseFloat(window.web3.utils.fromWei(userLPLT_Balance, "ether")).toFixed(4).toString()   
    //const nftSymbol = await BEP20Contract.methods.symbol().call();
    //nftBalance = nftBalance.toString() + nftSymbol;
    // nftBalance = parseFloat(window.web3.utils.fromWei(nftBalance, "ether")).toFixed(3).toString() + " " + nftSymbol;
    return userLPLT_BalanceString;
  }
  //  create new MR NFT Item Kind
  const CreateMrNftItem = async () => {
    const etherPrice = utils.parseEther(itemPrice.toString())
    const etherRate = utils.parseEther(itemRate.toString())
    
    const BEP721Contract = await getBEP721Contract();
    // console.log(BEP721Contract);

    

    const res = await BEP721Contract.methods.mintMrId(itemName, etherRate, etherPrice, 
      itemImageURI, itemMaxCount)
      .send({
        from: walletAddress
      });
      
    
    setStatus("creating item success!");
  }

  // fetch Item in Shop
  const fetchNftItemFromShop = async () => {
    setLoading(true)
    const BEP721Contract = await getBEP721Contract();
    const itemKindCount = await BEP721Contract.methods.getMrItemKindCount().call();
    console.log("itemKindCount", itemKindCount);

    const uri = await BEP721Contract.methods.baseURI().call() 
    setBaseURI(uri)

    let result = await BEP721Contract.methods.fetchItemFromShop().call();
    result = JSON.parse(result)

    var i = 0;
    // let id, name, rate, price, imageURI;
    let metaData = {};
    for(i <= 0; i < result.length; i++)
    {
      metaData = await axios.get(uri + result[i].mrMetaDataURI);
      
      result[i].name= metaData.data.name;
      result[i].description= metaData.data.description;
      result[i].rate= metaData.data.rate;
      result[i].imageURI = metaData.data.image;
      result[i].date = metaData.data.date;
    }
    console.log(result)
    setItems(result)
    setLoading(false)
  }

  const purchaseItemFromShop = async (itemId, count) => {
    const BEP721Contract = await getBEP721Contract();
    
    const res = await BEP721Contract.methods.mintToken(walletAddress, itemId, count)
      .send({
        from: walletAddress
      });
  }

  const fetchUserInventory = async (address) => {
    const BEP721Contract = await getBEP721Contract();

    let result = await BEP721Contract.methods.fetchUserInventory(address).call();
    result = JSON.parse(result)

    let metaData = {};
    for (let i = 0; i < result.length; i++)
    {
      metaData = await axios.get(result[i].metaDataURI);
      result[i].name= metaData.data.name;
      result[i].description= metaData.data.description;
      result[i].rate= metaData.data.rate;
      result[i].imageURI = metaData.data.image;
    }
    console.log(">>>>>>>>>>>>>", result)
    setInventories(result)
  }

  const getUserTotalRate = async (address) => {
    const BEP721Contract = await getBEP721Contract();
    var ownedTokenCount = await BEP721Contract.methods.balanceOf(address).call();
    var i = 0;
    var rateArray = new Array();
    const itemKindCount = await BEP721Contract.methods.getMrItemKindCount().call();
    for ( i = 0; i < ownedTokenCount; i++)
    {
      var tokenId = await BEP721Contract.methods.tokenOfOwnerByIndex(address, i).call();
      var itemId = await BEP721Contract.methods.getMrId(tokenId).call();

      for(var j = 0; j < itemKindCount; j++)
      {
        if(itemId == j)
          rateArray[j]++;
      }      
    }  
    var totalRate = 0;
    for(i = 0; i < itemKindCount; i++)  
    {
      if(rateArray[i] > 0)
        totalRate += await BEP721Contract.methods.getMrRate(i).call();
    }
    console.log("address= ", address, totalRate);
    return totalRate;
  }

  const getMarketplaceInfo = async () =>
  {

  }

  const setNftItemSellSate = async (tokenId, state, price) => {
    console.log("gggggggggggggggg", tokenId, state, price);
    const BEP721Contract = await getBEP721Contract();
    const tokenPrice = utils.parseEther(price.toString())
    const tokenState = state == "0" ? 1 : 0;
    const res = await BEP721Contract.methods.setUserNftSellState(tokenId, tokenPrice, tokenState)
      .send({
        from: walletAddress
      })
    console.log(res)


  }

  const getNftItemSellSate = async (tokenId) =>{
    const BEP721Contract = await getBEP721Contract();
    var state = await BEP721Contract.methods.getUserNftSellState(tokenId).call();
    return state;
  }

  const setUserNftItemPrice = async (tokenId, price) =>{
    const BEP721Contract = await getBEP721Contract();
    const etherPrice = utils.parseEther(price.toString())
    const res = await BEP721Contract.methods.setUserMrPrice(tokenId, etherPrice)
      .send({
        from: walletAddress
      });
  }

  const buyUserItem = async (from, to, tokenId) => {
    const BEP721Contract = await getBEP721Contract();
    const res = await BEP721Contract.methods.safeTransferFrom2(from, walletAddress, tokenId)
      .send({
        from: walletAddress
      });
  }

  // try conneting Wallet Event
  const onConnect = async () => {
    let providerObj;
    try {
      providerObj = await window.web3Modal.connect();
      window.provider = providerObj
    } catch (e) {
      console.log("Could not get a wallet connection", e);
      return;
    }
    providerObj.on("accountsChanged", (accounts) => {
      console.log(`accountsChanged = ${accounts}`);
      //fetchAccountData();
    });
    providerObj.on("chainChanged", (chain_id) => {
      console.log(`chainChanged ${chain_id}`);
      fetchAccountData();
    });

    providerObj.on("disconnect", (error) => {
      console.log(`disconnect ${error}`);
      onDisconnect();
    });
    await fetchAccountData();
  }

  const onDisconnect = async () => {

    if (window.provider.close) {
      await window.provider.close();
      await window.web3Modal.clearCachedProvider();
      window.provider = null;
    }
    setWalletAddress(null);
    setConnected(false);
    set_BNB_Balance(0);
    set_LPLT_Balance(0);
  }
  const handleChangeInput = (e) => {
    setMintCount(e.target.value)
  }

  const handleMint = async (id, price) => {
    console.log("id: ", id)
    console.log("price: ", price)
    if(mintCount === "" || mintCount === 0) {
      alert("Empty!")
      return;
    }
    const BEP721Contract = await getBEP721Contract();
    
    await BEP721Contract.methods.mintToken(walletAddress, id, mintCount)
      .send({
        from: walletAddress,
        value: price * mintCount
      })
      .on("receipt", (receipt) => {
        console.log(receipt)
        fetchUserInventory(walletAddress)
        alert("Mint Success")

      })
      .on("error", (err) => {
        console.log(err)
        alert(err)
      })
    
  }

  //the UI of our component
  return (
    <div id="container">
      <div>
        {BNB_balance} BNB
      </div>
      <div>
        {LPLT_Balance} LPLT
      </div>
      <button id="walletButton" onClick={onConnect}>
        {(walletAddress !== null && walletAddress.length > 0) ? (
          "Connected: " +
          String(walletAddress).substring(0, 6) +
          "..." +
          String(walletAddress).substring(38)
        ) : (
          <span>Connect Wallet</span>
        )}
      </button>
      {
        connected && (
          <button onClick={onDisconnect}>DISCONNECT</button>
        )
      }

      <h1>Admin Page</h1>

      <h2 className="d-flex justify-content-between align-items-center" style={{ paddingTop: "18px" }}>
        New Nft Item:
        {
          connected && (
            <button onClick={CreateMrNftItem} className="btn-open-shop">Create New Item</button>
          )
        }
      </h2>

      <div>        
        <input
          type="text"
          placeholder="Name"
          onChange={(e) => setItemName(e.target.value)}
          value={itemName}
        />
        <input
          type="text"
          placeholder="Rate"
          onChange={(e) => setItemRate(e.target.value)}
          value={itemRate}
        />
        <input
          type="text"
          placeholder="Price"
          onChange={(e) => setItemPrice(e.target.value)}
          value={itemPrice}
        />
        <input
          type="text"
          placeholder="Image URI"
          onChange={(e) => setItemImageURI(e.target.value)}
          value={itemImageURI}
        />
        <input
          type="text"
          placeholder="Count"
          onChange={(e) => setItemMaxCount(e.target.value)}
          value={itemMaxCount}
        />
        <p id="status">{status}</p>

        {/* <button id="publish" onClick={onUpdatePressed}>
          Update
        </button> */}
      </div>
      <hr />
      <h1>Client Page</h1>
      <h2>My Inventory</h2>
      <div className="row">
      {
          inventories.length > 0 && inventories.map((item, index) => (
          <div className="col-3 col-lg-3" key={index} style={{ padding: '5px'}}>
            <InventoryCard
              data={item} 
              handleSellState={setNftItemSellSate} 
            />
          </div>
          ))
        }
      </div>
      <hr />
      <h2 className="d-flex justify-content-between align-items-center">
        Shop
        {
            connected && (
              <button onClick={fetchNftItemFromShop} className="btn-open-shop">Open Shop</button>
            )
        }
      </h2>
      <div className="row">
        {
          items.length > 0 && items.map((item, index) => (
          <div className="col-3 col-lg-3" key={index} style={{ padding: '5px'}}>
            <ShopCard 
              data={item} 
              handleChangeInput={handleChangeInput} 
              handleMint={handleMint} 
            />
          </div>
          ))
        }
      </div>

      <hr />

      <h2>MarketPlace</h2>
      <div className="row">
        {
          itemList.map((item, index) => (
          <div className="col-3 col-lg-3" key={index} style={{ padding: '5px'}}>
            <MarketCard data={item} handleChangeInput={handleChangeInput} handleMint={handleMint} />
          </div>
          ))
        }
      </div>
      
    </div>
  );
};

export default MineRight;
