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

const tezbridge = window.tezbridge;
const tezos = new TezosToolkit("https://rpctest.tzbeta.net");

//https://rpctest.tzbeta.net

function App() {
  var [ktBalance, setKtBalance] = useState(undefined);
  const [ledgerInstance, setLedgerInstance] = useState(undefined);
  const [userAddress, setUserAddress] = useState(undefined);
  var [balance, setBalance] = useState(undefined);
  //const tezbridge = window.tezbridge;
  //const tezos = new TezosToolkit("http://localhost:8732");

  useEffect(() => {
    (async () => {
      // set tezos Signer
      tezos.setProvider({
        signer: new TezBridgeSigner()
      });
      const _ledgerContract = await tezos.contract.at(KT_ledger);
      setLedgerInstance(_ledgerContract);
      var _ktBalance = await tezos.rpc.getBalance(KT_ledger) / 1000000;
      setKtBalance(_ktBalance);
    })();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const initWallet = async () => {
    try {
      const _address = await tezbridge.request({ method: "get_source" });
      setUserAddress(_address);
      // gets user's balance
      var _balance = await tezos.rpc.getBalance(_address);
      setBalance(_balance);
    } catch (error) {
      console.log("error fetching the address or balance:", error);
    }
  };

  return (
    <div className="App">
      <div className="app-title">Bet on SSE Composite Index on {shortenAddress(KT_ledger)},
      <p>with { ktBalance } </p>
      </div>
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
                    await initWallet();
                  }}
                >
                  {shortenAddress(userAddress)}
                </button>
              </p>
              {(
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
          tezos={tezos}
          setKtBalance={setKtBalance}
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
