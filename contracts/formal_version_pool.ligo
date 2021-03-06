type storage is 
record [
    current_result : nat;
    target_date : string;
    oracleAddress : address;
    ybalance : nat;
    nbalance : nat;
    register : map(address, bool);
    stake : map(address, nat);
    last_cancelled : string;
    last_distributed : string;
    accounts : map(address,nat);
]
type return is list(operation) * storage
type actions is 
| GetResult of string
| SetTargetdate of string
| AdminWithdrawal of tez  
| Bet of bool
| HandleCallback of nat
| Withdrawal 
const start_timestamp : timestamp = ("1970-01-01T00:00:00Z" : timestamp)

function sum_map (var m : map (address, nat)) : nat is block {
  var int_total : nat := 0n;
  for key -> value in map m block {
    int_total := int_total + value
  }
} with (int_total)

function validatingamount (const s : storage) : unit is 
block {
  const n : unit = Unit;
  if Tezos.balance < (s.nbalance + s.ybalance + sum_map(s.accounts)) * 1mutez then failwith ("Cannot make any operation as the balance of the contract is smaller than the pool") else skip;
} with n

function adminwithdrawal (const amt : tez; var s : storage) : return is
block {

    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    const total_value : nat = sum_map(s.accounts);
    if Tezos.balance < (s.nbalance + s.ybalance + total_value +10000000n) * 1mutez + amt then failwith ("Admin cannot make any operation as the balance of the contract is smaller than the pool") else skip;
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
  //below is to make sure bet function only opens from 0830 to 0900, i.e.,local time 1630 to 1700
  if ((Tezos.now - start_timestamp - 30_600n ) mod 86_400n > 1800n) then failwith ("bet deadline for today") else skip;
  if Tezos.amount < 1.0tez then failwith ("the amount must be larger than 1 tezos") else skip;
  case s.stake[Tezos.sender] of 
    Some(pattern) -> failwith ("It is on the current list.") 
  | None -> skip
  end;
  s.stake[Tezos.sender] := Tezos.amount/1mutez;
  s.register[Tezos.sender] := betbool;
  if betbool = True then
  block {
    s.ybalance := s.ybalance + Tezos.amount / 1mutez;
  } else skip;
  if betbool = False then
  block {
    s.nbalance := s.nbalance + Tezos.amount / 1mutez;
  } else skip;
} with ((nil : list(operation)),s)

function setTargetdate(const ndate : string; var s : storage) : return is 
block {
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    s.target_date := ndate;
} with ((nil: list(operation)),s)

function handleCallback(const orcvalue : nat; var s : storage) : return is
block{
  if orcvalue = 0n then failwith("something wrong with fetched result!") else skip;
  s.current_result := orcvalue;
  if orcvalue = 1n then
  block {
    for key -> value in map s.register block {
      if value = False then 
      block {
        case s.stake[key] of 
          Some(found) -> s.stake[key] := found *  s.ybalance / s.nbalance + found
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
          Some(found) -> s.stake[key] := found *  s.nbalance / s.ybalance + found
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
  s.ybalance := 0n;
  s.nbalance := 0n;
  const empty_stake : map (address, nat) = map [];
  const empty_register : map (address, bool) = map [];
  s.stake := empty_stake;
  s.register := empty_register;
}with ((nil: list(operation)),s);

function getResult(const tdate: string; var s : storage) : return is 
block{
    if ((Tezos.now - start_timestamp - 28_800n ) mod 86_400n > 1800n) then failwith ("getresult only runs from local 1600 to 1630") else skip;
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    var resp : list(operation) := nil;
    if tdate =/= s.target_date then failwith ("Not the target date to run") else skip;
    if (s.ybalance / s.nbalance > 100n) or (s.nbalance / s.ybalance > 100n) then 
    block {
     s.last_cancelled := tdate;
     s.current_result := 0n;
     for key -> value in map s.stake block {
       case s.accounts[key] of
         Some(pattern) -> s.accounts[key] := pattern + value
       | None -> s.accounts[key] := value
       end;
     }
    } else 
    block {
      s.last_distributed := tdate;
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