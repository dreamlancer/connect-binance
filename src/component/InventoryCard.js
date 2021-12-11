// import Img1 from './assets/1.jpg'

import { useEffect, useState } from "react";
import { utils } from "ethers";

const InventoryCard = ({ 
    data, 
    handleSellState, 
}) => {

    const [sellPrice, setSellPrice] = useState(0)

    useEffect(() => {
        setSellPrice(parseFloat(window.web3.utils.fromWei(data.price, "ether")).toFixed(4).toString())
    }, [])

    const handleChangePrice = (e) => {
        setSellPrice(e.target.value)
    }

    return (
        <div style={{border: '1px solid #ddd', borderRadius: '5px', backgroundColor: '#392960'}}>
            <img src={data.imageURI} alt="" style={{width: '100%'}} />

            <div className="description" style={{padding: '5px 10px'}}>
                <p>
                    <input 
                        type="text" 
                        className="form-control-sm w-100" 
                        onChange={handleChangePrice} 
                        style={{borderStyle: 'solid', borderColor: '#fff', borderWidth: '1px', borderRadius: '5px', width: '50%', backgroundColor: 'transparent', color: '#fff'}} 
                        value={sellPrice}
                    />
                </p>
                <p className="text-center"><span className="m-auto w-100 text-center" onClick={(e) => {
                    handleSellState(data.tokenId, data.tokenSellState, sellPrice);                    
                }} style={{cursor: 'pointer', color:'white', padding: '3px 5px', border: '1px solid #ddd', borderRadius: '3px'}}>
                    { data.tokenSellState === 1 ? 'Cancel Sell State' : 'Set Sell State'}
                </span>
                </p>
            </div>
        </div>
    )
}

export default InventoryCard;