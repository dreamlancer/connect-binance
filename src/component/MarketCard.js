import Img1 from '../assets/1.jpg'

const MarketCard = ({ data, handleMint, handleChangeInput }) => {
    return (
        <div style={{border: '1px solid #ddd', borderRadius: '5px', backgroundColor: '#392960'}}>
            <img src={Img1} alt="" style={{width: '100%'}} />
            <div className="description" style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px'}}>
                <input 
                    type="text" 
                    className="form-control" 
                    onChange={handleChangeInput} 
                    style={{borderStyle: 'solid', borderColor: '#fff', borderWidth: '1px', borderRadius: '5px', width: '50%', backgroundColor: 'transparent', color: '#fff'}} 
                />
                {/* <button type="button" className="btn btn-success" onClick={(e) => handleClick(data.id)} style={{cursor: 'pointer', color:'white'}}>Mint</button> */}
                <span onClick={(e) => handleMint(data.id)} style={{cursor: 'pointer', color:'white', padding: '3px 8px', border: '1px solid #ddd', borderRadius: '3px'}}>Buy</span>
            </div>
        </div>
    )
}

export default MarketCard;