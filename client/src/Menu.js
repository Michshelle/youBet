import React, { useState } from "react";

//const mutezToTez = mutez =>
//  Math.round((parseInt(mutez) / 1000000 + Number.EPSILON) * 100) / 100;

const Menu = ({
  tezos,
  ledgerInstance,
  userAddress,
  setBalance,
  setKtBalance,
  ktBalance,
}) => {
  const [isBurnt, setIsBurnt] = useState(false);

  const bet = async (new_owner,bool_bet) => {
    try {
      //const ledgerStorage = await ledgerInstance.storage()
      //const userLedger = await ledgerStorage.register.get(userAddress)
      const op = await ledgerInstance.methods
        .bet(new_owner, bool_bet)
        .send({ amount: 3000000, mutez: true });
      await op.confirmation(10);
      if (op.includedInBlock !== Infinity) {
        const newBalance = await tezos.rpc.getBalance(userAddress);
        setBalance(newBalance);
        alert("Transfer is done!")
      } else {
        throw Error("Transation not included in block");
      }
    } catch (error) {
      console.log(error);
    }
  }

  const burn = async () => {
    try {
      const op = await ledgerInstance.methods.withdrawal().send({ amount: 0 });
      await op.confirmation(30);
      if (op.includedInBlock !== Infinity) {
        const newBalance = await tezos.rpc.getBalance(userAddress);
        setBalance(newBalance);
        setIsBurnt(true);
        alert("Withdrawal is done!")
      } else {
        console.log("Transaction is not included in the block");
      }
    } catch (error) {
      console.log(error);
    }
  };
  return (
    <>
        <div className="app-subtitle">Choose the action you want to perform:</div>
            <div className="card coffee_selection" key={userAddress}>
              <div className="card-footer">
                <div className="card-footer-item">
                { isBurnt === undefined ? (
                  <span
                    className="action"
                    onClick={async () => {
                      setIsBurnt(undefined);
                      await burn();
                    }
                 }
                  >
                    Burn
                  </span>
                ) : (
                   <span 
                      className="actioned"  
                   >
                     Burnt
                   </span> 
                )}          
                </div>
                <div className="card-footer-item">
                  <div className="card-padding-line"> 
                   New creditor: 
                  </div>
                  <div className="card-padding-line">
                   <input type="text" id="newCreditorAccount" ></input>
                  </div>
                  <span
                    className="action"
                    onClick={async () => {
                      await bet(document.getElementById("newCreditorAccount").value)
                      }
                    }
                  >
                    Bet
                  </span>                             
                </div>
              </div>
            </div>
    </>
  );
};
    
export default Menu;