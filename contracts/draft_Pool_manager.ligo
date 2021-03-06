type mmap is map(address,nat);
type storage is 
record [
    currentResult : nat;
    targetDate : string;
    oracleAddress : address;
    yBalance : nat;
    nBalance : nat;
    register : map(address, bool);
    stake : map(address, nat);
    lastCancelled : string;
    lastDistributed : string;
    accounts : mmap;
]

type mmap is map(address,nat);
type return is list(operation) * storage
type actions is 
| GetResult of string
| SetTargetdate of string
| AdminWithdrawal of tez  
| Bet of (bool) 
| HandleCallback of nat
| Withdrawal 

const empty_stake : map (address, nat) = map [];
const empty_register : map (address, bool) = map [];

function sum_map (var m : map (address, nat)) : nat is block {
  var int_total : nat := 0n;
  for key -> value in map m block {
    int_total := int_total + value
  }
} with (int_total)

function delete (const key : address; var moves : mmap) : mmap is
  block {
    remove key from map moves
  } with moves

function validatingamount (const s : storage) : unit is 
block {
  const n : unit = Unit;
  if Tezos.balance < (s.nBalance + s.yBalance + sum_map(s.accounts)) * 1mutez then failwith ("Cannot make any operation as the balance of the contract is smaller than the pool") else skip;
} with n

function adminwithdrawal (const amt : tez; var s : storage) : return is
block {
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    const total_value : nat = sum_map(s.accounts);
    if Tezos.balance < (s.nBalance + s.yBalance + total_value +10000000n) * 1mutez + amt then failwith ("Admin cannot make any operation as the balance of the contract is smaller than the pool") else skip;
    const execontract : contract (unit) =
        case (Tezos.get_contract_opt (Tezos.sender) : option (contract (unit))) of
          Some (contract) -> contract
        | None -> (failwith ("Contract not found.") : contract (unit))
        end;
    var op : operation := Tezos.transaction (unit, amt, execontract);
    var ops : list(operation) := nil;
    ops := list[op];
} with (ops,s)

function withdrawal ( var s : storage) : return is
block {
  validatingamount(s);
  case s.register[Tezos.sender] of 
     Some(_share) -> failwith ("May withdrawal after the coming round of gambling!") 
    | None -> skip
  end;
  var ops : list(operation) := nil;
  case s.accounts[Tezos.sender] of
    Some(pattern) -> block {
    const execontract : contract (unit) =
        case (Tezos.get_contract_opt (Tezos.sender) : option (contract (unit))) of
          Some (contract) -> contract
        | None -> (failwith ("Contract not found.") : contract (unit))
        end;
      const smt : tez = 1mutez * pattern;
      const op : operation = Tezos.transaction (unit, smt, execontract);
      ops := list[op];
      remove Tezos.sender from map s.accounts;
    }
   | None -> failwith ("Your address is not in the log")
  end; 
} with (ops,s)

function bet (const betbool : bool; var s : storage) : return is
block {
  validatingamount(s);
  if Tezos.amount < 1.0tez then failwith ("the amount must be larger than 1 tezos") else skip;
  case s.stake[Tezos.sender] of 
    Some(pattern) -> failwith ("It is on the current list.") 
  | None -> skip
  end;
  s.stake[Tezos.sender] := Tezos.amount/1mutez;
  s.register[Tezos.sender] := betbool;
  if betbool = True then
  block {
    s.yBalance := s.yBalance + Tezos.amount / 1mutez;
  } else skip;
  if betbool = False then
  block {
    s.nBalance := s.nBalance + Tezos.amount / 1mutez;
  } else skip;
} with ((nil : list(operation)),s)

function setTargetdate(const ndate : string; var s : storage) : return is 
block {
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    s.targetDate := ndate;
} with ((nil: list(operation)),s)

function handleCallback(const orcvalue : nat; var s : storage) : return is
block{
  if orcvalue = 0n then failwith("something wrong with fetched result!") else skip;
  //in this case, tezos.sender is actually the oracle contract
  if Tezos.sender =/= s.oracleAddress then failwith ("Only can be executed by the manager itself") else skip;
  s.currentResult := orcvalue;
  if orcvalue = 1n then
  block {
    for key -> value in map s.register block {
      if value = False then 
      block {
        case s.stake[key] of 
          Some(found) -> s.stake[key] := found *  s.yBalance / s.nBalance + found
        | None -> failwith ("register pool and stake pool are not consistent!")
        end;
      } else s.stake[key] := 0n;
    }
  } else skip;
  if orcvalue  = 2n then
  block {
    for key -> value in map s.register block {
      if value = True then 
      block {
        case s.stake[key] of 
          Some(found) -> s.stake[key] := found *  s.nBalance / s.yBalance + found
        | None -> failwith ("register pool and stake pool are not consistent!")
        end;
      } else s.stake[key] := 0n;
    }
  } else skip;
  for key -> value in map s.stake 
  block {
    case s.accounts[key] of
      Some(pattern) -> s.accounts[key] := value + pattern
    | None -> s.accounts[key] := value
    end;
  };
  s.yBalance := 0n;
  s.nBalance := 0n;
  s.stake := empty_stake;
  s.register := empty_register;
  for key -> value in map s.accounts block {
    if value = 0n then block { 
        s.accounts := delete(key,s.accounts) 
    } else skip;
  }
}with ((nil: list(operation)),s);

function getResult(const tdate: string; var s : storage) : return is 
block{
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    var resp : list(operation) := nil;
    if tdate =/= s.targetDate then failwith ("Not the target date to run") else skip;
    if ( s.yBalance / (s.nBalance + 1n) > 100n) or (  s.nBalance / (s.yBalance + 1n) > 100n) then 
    block {
     s.lastCancelled := tdate;
     s.currentResult := 0n;
     for key -> value in map s.stake block {
       case s.accounts[key] of
         Some(pattern) -> s.accounts[key] := pattern + value
       | None -> s.accounts[key] := value
       end;
     };
      s.yBalance := 0n;
      s.nBalance := 0n;
      s.stake := empty_stake;
      s.register := empty_register;
    } else 
    block {
      s.lastDistributed := tdate;
      var oracle : contract(contract(nat)) := 
      case(Tezos.get_entrypoint_opt("%getData", s.oracleAddress) : option (contract(contract(nat)))) of
       Some(c) -> c
      | None -> failwith("Oracle not found")
      end;
      var param : contract(nat) := 
      case(Tezos.get_entrypoint_opt("%handleCallback", Tezos.self_address) : option(contract(nat))) of
      Some(p) -> p
      | None -> failwith("Callback func not found")
      end;
      resp := list [Tezos.transaction(param,0mutez,oracle)];
    };
} with (resp,s);

function main (const p : actions; const s : storage) : return is
case p of 
| GetResult(t) -> getResult(t,s)
| SetTargetdate(t) -> setTargetdate(t,s)
| AdminWithdrawal(t) -> adminwithdrawal(t,s)
| Withdrawal ->  withdrawal(s)
| HandleCallback(n) -> handleCallback(n,s)
| Bet(t) -> bet(t,s)
end
