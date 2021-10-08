import React, { useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { TezBridgeSigner } from "@taquito/tezbridge-signer";
import "./App.css";
import "./bulma.css";
import Menu from "./Menu.js"

/* PUT HERE THE CONTRACT ADDRESS FOR YOUR OWN SANDBOX! */
const KT_ledger = "KT1FfBHieCMYD22ytpycXjNrM36T8gZjdbGB"  //some of the QC rules have been removed;
const Oracle_contract = "KT19LmmajQN5j8b5T2AxX6YJbxwiLoybKWYF"
const shortenAddress = addr =>
  addr.slice(0, 6) + "..." + addr.slice(addr.length - 6);

const tezbridge = window.tezbridge;
//const tezos = new TezosToolkit("http://localhost:8732");
const tezos = new TezosToolkit("https://rpctest.tzbeta.net");


function App() {
  var [ktBalance, setKtBalance] = useState(undefined);
  var [ledgerInstance, setLedgerInstance] = useState(undefined);
  const [oracleData, setOracleData] = useState([]);
  const [userAddress, setUserAddress] = useState(undefined);
  var [balance, setBalance] = useState(undefined);

  useEffect(() => {
    (async () => {
      // set tezos Signer
      tezos.setProvider({
        signer: new TezBridgeSigner()
      });
      const _ledgerContract = await tezos.contract.at(KT_ledger);
      setLedgerInstance(_ledgerContract);
      const _oracle = await tezos.contract.at(Oracle_contract);
      const _oracleStorage = await _oracle.storage();
      let _oracleData = [_oracleStorage.currentd,_oracleStorage.currentq.c,_oracleStorage.previousd,_oracleStorage.previousq.c];
      setOracleData(_oracleData);
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
      <div className="sidenav">Oracle contract: <a href="https://better-call.dev/granadanet/KT19LmmajQN5j8b5T2AxX6YJbxwiLoybKWYF/operations">{shortenAddress(Oracle_contract)}</a>
        <p>Last Round:</p>
        <table>
          <tbody>
          <tr>
            <td className="column">{oracleData[0] === undefined ? (<>Loading</>) : (<>{oracleData[0]}</>)}</td>
            <td className="cell">{oracleData[1] === undefined ? (<>Loading</>) : (<>{oracleData[1] / 1000000}</>) }</td>
          </tr>
          <tr>
            <td className="column">{oracleData[2] === undefined ? (<>Loading</>) : (<>{oracleData[2]}</>)}</td>
            <td className="cell">{oracleData[3] === undefined ? (<>Loading</>) : (<>{oracleData[3] / 1000000}</>) }</td>
          </tr>
          </tbody>
        </table>
      </div>
      <div className="app-title">Bet on SSE Index</div>
      <div className="app-subtitle">under <a href="https://better-call.dev/granadanet/KT1NhgBVPmnHgpoWJ7fbuEhGY2Qqb8coNQsi/operations">{shortenAddress(KT_ledger)}</a>
      <p>Current pool balance: {ktBalance === undefined ? (<>Loading</>) : (<>{ktBalance}</>) }</p>
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
                  {":   "}
                  {balance.c/1000000}
                </button>
              </p>
            </div>
          </>
        )}
      </div>
      {typeof ledgerInstance === 'undefined' ? (
        "Loading the ledger info..."
      ) : (
        <Menu
          tezos={tezos}
          tezbridge={tezbridge}
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
