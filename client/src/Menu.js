import React, { useState } from "react";
import MyApp from "./datetimepicker";
import moment from "moment";


const shortenAddress = addr =>
  addr.slice(0, 6) + "..." + addr.slice(addr.length - 6);

//const mutezToTez = mutez =>
//  Math.round((parseInt(mutez) / 1000000 + Number.EPSILON) * 100) / 100;

const Menu = ({
  ledgerInstance,
  ledgerInfo,
  userAddress,
  setBalance,
  Tezos
}) => {

  const [burnBalance, setBurnBalance] = useState(undefined);
  const [myAppDate, setMyAppDate] = useState(new Date());

  const debtTokenTransfer = async (new_owner,start_date) => {
    try {
      const ledgerStorage = await ledgerInstance.storage()
      const interestRate = ledgerStorage.couponRate_inPerc
      const userLedger = await ledgerStorage.creditorsMap.get(userAddress)
      const start_date_timestamp = Date.parse(start_date) / 1000
      const creditCapital = userLedger.creditAmount
      const initialTime_timestamp = Date.parse(moment(userLedger.initialTime)) / 1000
      const day_diff = Math.floor((start_date_timestamp - initialTime_timestamp) / 86400)
      const parsed_date = moment(start_date_timestamp * 1000).utcOffset('+00').format('YYYY-MM-DDThh:mm:ssZ').toString()
      const parsed_data = parsed_date.replace("+00:00","Z")
      const paybackAmount = Math.round(creditCapital * ( 1 + interestRate / 1000000) ** day_diff - creditCapital)
      const str_payback = "Payback Amount: "
      const str_combo = str_payback.concat(paybackAmount, " ",parsed_data, new_owner)
      alert(str_combo)
      const op = await ledgerInstance.methods
        .modifyOwnership(new_owner, parsed_data, paybackAmount)
        .send({ amount: 3000000, mutez: true });
      await op.confirmation(30);
      if (op.includedInBlock !== Infinity) {
        const newBalance = await Tezos.tz.getBalance(userAddress);
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
      const ledgerStorage = await ledgerInstance.storage()
      if (userAddress === ledgerStorage.owner) { 
        throw Error("The burn on webpage is only designed for creditors! Use commandline to burn as the token owner! ");
      }
      const userToken = await ledgerStorage.ledger.get(userAddress)
      const balanceToken = userToken.balance
      if (typeof balanceToken === "undefined") { 
        throw Error("Cannot find the account possesses any debt token. ");
      }
      const req = await fetch("https://cors-anywhere.herokuapp.com/https://api-pub.bitfinex.com/v2/ticker/tXTZUSD", { headers : { 'Access-Control-Allow-Origin': '*' }})
      const response = await req.json()    
      const xtzPrice = Number(response[0])
      const amounts = Math.round(balanceToken / xtzPrice)  //in mutez
      const settlement = "XTZ"  //this can be an option in future at the frontend.  The settlement can be in USD and etc.
      const op = await ledgerInstance.methods.burn(settlement, amounts, 0).send({ amount: 0 });
      await op.confirmation(30);
      if (op.includedInBlock !== Infinity) {
        const newBalance = await Tezos.tz.getBalance(userAddress);
        setBalance(newBalance);
        setBurnBalance(newBalance);
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
          <p>USD{ ledgerInfo[1] /1000000 } has been raised for the debt account { shortenAddress(ledgerInfo[0]) }.</p>
            <div className="card coffee_selection" key={userAddress}>
              <div className="card-footer">
                <div className="card-footer-item">
                { burnBalance === undefined ? (
                  <span
                    className="action"
                    onClick={async () => {
                      setBurnBalance(undefined);
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

                  <div>
                  <MyApp onDateChange={(date)=>{setMyAppDate(date)}} />
                  </div>
                  <span
                    className="action"
                    onClick={async () => {
                      await debtTokenTransfer(document.getElementById("newCreditorAccount").value,myAppDate)
                      }
                    }
                  >
                    Transfer Ownership
                  </span>                             
                </div>
              </div>
            </div>
    </>
  );
};
    
export default Menu;
