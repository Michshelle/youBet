import React, { useState } from "react";


//const mutezToTez = mutez =>
//  Math.round((parseInt(mutez) / 1000000 + Number.EPSILON) * 100) / 100;

const Menu = ({
  tezos,
  tezbridge,
  ledgerInstance,
  userAddress,
  setBalance,
  setKtBalance,
  ktBalance,
}) => {
  const [isBurnt, setIsBurnt] = useState(false);

//const bet = async (stake_amount,bool_bet) => {
//  try {
//    alert("0 is done!");
//    const op = await ledgerInstance.methods.bet('False').send({ amount: 1 * 1000000,fee: 100000, gasLimit: 1000000, mutez: true });
//    alert("1 is done!");
//    await op.confirmation(30);
//    alert("2 is done!");
//    if (op.includedInBlock !== Infinity) {
//      const newBalance = await tezos.rpc.getBalance(userAddress);
//      setBalance(newBalance);
//      alert("Transaction is done!")
//    } else {
//      throw Error("Transation not included in block");
//    }
//  } catch (error) {
//    console.log(error);
//  }
//}

const bet = async (stake_amount,bool_bet) => {
   var mut_number = stake_amount * 1000000;
   var str_stake_amount = mut_number.toString();
   tezbridge.request({
     method: 'inject_operations',
     operations: [
       {
        "kind": "transaction",
        "source": userAddress,
        "amount": str_stake_amount,
        "destination": ledgerInstance.address,
        "parameters":
        {
          "entrypoint":"bet",
          "value":
          {
            "prim":bool_bet
          }
        }
       }
     ]
   })
   .then(result => alert(JSON.stringify(result)))
   .catch(error => alert(error.toString()))
};

  const burn = async () => {
    tezbridge.request({
      method: 'inject_operations',
      operations: [
        {
          "kind": "transaction",
          "source": userAddress,
          "destination": ledgerInstance.address,
          "amount": "0",
          "parameters":
          {
              "entrypoint":"withdrawal",
              "value":
              {
                  "prim":"Unit"
              }
          }
        }
      ]
    })
    .then(result => setIsBurnt(true))
    .catch(error => alert(error.toString()))

  };

  return (
    <>
        <div className="app-subtitle">Choose the action you want to perform:</div>
            <div className="card index_selection" key={userAddress}>
              <div className="card-footer">
              {userAddress === undefined ? (<><div className="card-footer-item">Please connect your wallet</div></>) : (<><div className="card-footer-item">
                { isBurnt === false ? (
                  <span
                    className="action is-medium"
                    onClick={async () => {
                      setIsBurnt(false);
                      await burn();
                    }
                 }
                  >
                    Withdrawal
                  </span>
                ) : (
                   <span 
                      className="actioned is-medium"  
                   >
                     No Stake To Withdrawal
                   </span> 
                )}          
                </div>
                <div className="card-footer-item">
                  <div className="card-padding-line">
                  <form method="get"> 
                      Will go up in the coming round?<br />
                      <label><input name="trend" id="trend0" type="radio" value="False" />No   </label> 
                      <label><input name="trend" id="trend1" type="radio" value="True" />Yes  </label> 
                  </form>
                  <input type="text" id="amountOfStake" ></input>
                  </div>
                  <span
                    className="action is-medium" style={{"marginLeft":"10%"}}
                    onClick={async () => {
                      if (document.getElementById("trend0").checked) {
                        await bet(parseFloat(document.getElementById("amountOfStake").value),document.getElementById("trend0").value);
                      } 
                      else if (document.getElementById("trend1").checked) {
                        await bet(parseFloat(document.getElementById("amountOfStake").value),document.getElementById("trend1").value);
                      }
                    }
                  }
                  >
                    Bet
                  </span>                             
                </div>
                </>)}
                

              </div>
            </div>
    </>
  );
};
    
export default Menu;