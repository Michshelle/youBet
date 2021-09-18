import React, { useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { TezBridgeSigner } from "@taquito/tezbridge-signer";
import "./App.css";
import "./bulma.css";
import Menu from "./Menu.js"

/* PUT HERE THE CONTRACT ADDRESS FOR YOUR OWN SANDBOX! */
const KT_ledger = "KT1NhgBVPmnHgpoWJ7fbuEhGY2Qqb8coNQsi"  //some of the QC rules have been removed;
const shortenAddress = addr =>
  addr.slice(0, 6) + "..." + addr.slice(addr.length - 6);

function App() {
  const [ktBalance, setKtBalance] = useStae(undefined);
  const [ledgerInstance, setLedgerInstance] = useState(undefined);
  const [userAddress, setUserAddress] = useState(undefined);
  const [balance, setBalance] = useState(undefined);
  const [isOwner, setIsOwner] = useState(false);
  const tezbridge = window.tezbridge;
  const tezos = new TezosToolkit("http://localhost:8732");
  tezos.setProvider({ signer: new TezBridgeSigner() });

  const ktManager = await tezos.tz.getManager(KT_ledger);
  const _ktBalance = await tezos.tz.getBalance(KT_ledger).toNumber() / 1000000;
  setKtBalance(_ktBalance);


  const initWallet = async () => {
    try {
      const _address = await tezbridge.request({ method: "get_source" });
      setUserAddress(_address);
      // gets user's balance
      const _balance = await tezos.tz.getBalance(_address);
      setBalance(_balance);
      const storage = await ledgerInstance.storage();
      if (ktManager === _address) {
        setIsOwner(true);
      }
    } catch (error) {
      console.log("error fetching the address or balance:", error);
    }
  };

  useEffect(() => {
    (async () => {
      const _ledgerContract = await tezos.contract.at(KT_ledger);
      setLedgerInstance(_ledgerContract);
    })();
  }, []);

  return (
    <div className="App">
      <div className="app-title">Bet on SSE Composite Index</div>
      <div className="logo">
        <img src="tezos-maker.png" alt="logo" />
      </div>
      <div className="wallet">
        {balance === undefined ? (
          <button
            className="button is-info is-light is-small"
            onClick={initWallet}
          >
            Connect your wallet
          </button>
        ) : (
          <>
            <div className="field is-grouped">
              <p className="control">
                <button
                  className="button is-success is-light is-small"
                  onClick={async () => {
                    setUserAddress(undefined);
                    setBalance(undefined);
                    setIsOwner(undefined);
                    await initWallet();
                  }}
                >
                  {shortenAddress(userAddress)}
                </button>
              </p>
              {isOwner && (
                <p className="control">
                  <button
                    className="button is-warning is-light is-small"
                    onClick={async () => {

                    }
                    }
                  >
                    Bet
                  </button>
                </p>
              )}
            </div>
          </>
        )}
      </div>
      {typeof ledgerInstance === 'undefined' ? (
        "Loading the ledger info..."
      ) : (
        <Menu
          ktBalance={ktBalance}
          ledgerInstance={ledgerInstance}
          userAddress={userAddress}
          setBalance={setBalance}
        />
      )}
    </div>
  );
}

export default App;
