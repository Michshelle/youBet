type storage is 
record [
    current_result : nat;
    target_date : string;
    oracleAddress : address;
    ybalance : tez;
    nbalance : tez;
    register : map(address, bool);
    stake : map(address, tez);
    last_cancelled : string;
    last_distributed : string;
    accounts : big_map(address,tez);
]
type return is list(operation) * storage

type actions is 
| GetResult of string
| SetTargetdate of string
| HandleCallback of nat 
| AdminWithdrawal of (tez)  
| Bet of (bool) 
| Distribution of (nat)
| Sum_map of (big_map)
| ValidatingAmount
| Withdrawal 

function distribution (const orcvalue : nat; var s : storage) : storage is
block {
  if orcvalue = 1n then
  block {
    for key -> value in map s.register block {
      if s.register[key] = False then 
      block {
        s.stake[key] := s.stake[key] * s.ybalance / s.nbalance 
      } else 
      block {
        s.stake[key] := 0n;
      }
    }
  } else
  block {
    for key -> value in map s.register block {
      if s.register[key] = True then 
      block {
        s.stake[key] := s.stake[key] * s.ybalance / s.nbalance 
      } else 
      block {
        s.stake[key] := 0n;
      }
    }
  }
  for key -> value in map s.stake block {
    case s.accounts[key] of
      Some(pattern) -> s.accounts[key] := s.accounts[key] + s.stake[key]
    | None -> s.accounts[key] := s.stake[key]
    end;
  }
} with s

function adminwithdrawal (const amt : tez; var s : storage) : return is
block {
    if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator") else skip;
    if Tezos.balance < s.nbalance + s.ybalance + sum_map(s.accounts) +10000000mutez then failwith ("Admin cannot make any operation as the balance of the contract is smaller than the pool") else skip;
    const op : operation = Tezos.transaction (unit, amt, Tezos.sender);
    ops := list[op];
} with (ops,s)

function withdrawal ( var s : contract_storage) : return is
block {
  validatingamount(s);
  case s.register[Tezos.sender] of 
    Some(share) -> (faliwith ("May withdrawal after the coming round of gambling!") : bool)
    | None -> skip
  end;
  const ops : list(operation) = list [];
  case s.accounts[Tezos.sender] of
    Some(pattern) -> block {
      const op : operation = Tezos.transaction (unit, amt, Tezos.sender);
      ops := list[op];
      s.accounts := Big_map.update(Tezos.sender, None, s.accounts);
    }
   | None -> failwith ("Your address is not in the log");
  end; 
} with (ops,s)

function bet (const betbool : bool; var s : contract_storage) : storage is
block {
  validatingamount(s);
  if amount < 1.0tez then failwith ("the amount must be larger than 1 tezos") else skip;
  case s.stake[Tezos.sender] of 
    Some(pattern) -> (failwith ("It is on today's list.") : tez)
  | None -> skip
  end;
  s.stake[Tezos.sender] := amount;
  s.register[Tezos.sender] := betbool;
} with s

function sum_map (var m : big_map (address, tez)) : tez is block {
  var int_total : tez := 0tez;
  for key -> value in big_map m block {
    int_total := int_total + value
  }
} with (int_total)

function validatingamount (var s : contract_storage) : contract_storage is 
block {
  if Tezos.balance < s.nbalance + s.ybalance + sum_map(s.accounts) then failwith ("Cannot make any operation as the balance of the contract is smaller than the pool") else skip;
}

function getResult(const tdate: string; var s : storage) : return is 
block{
    var resp : list(operation) := nil;
    if tdate =/= s.target_date then failwith ("Not the target date to run") else skip;

    if s.ybalance / s.nbalance < 100n or s.nbalance / s.ybalance < 100n then 
    block {
     s.last_cancelled := tdate
     s.current_result := 0
     for key -> value in map s.stake block {
       case s.accounts[key] of
         Some(pattern) -> s.accounts[key] := s.accounts[key] + s.stake[key]
       | None -> s.accounts[key] := s.stake[key]
       end;
     }
    } else 
    block {
      s.last_distributed := tdate
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
    }
    ybalance := 0tez
    nbalance := 0tez
    s.stake := map []
    s.register := map []
} with (resp,s);

function setTargetdate(const ndate : string; var s : storage) : return is 
block {
    s.target_date := ndate;
} with ((nil: list(operation)),s)

function handleCallback(const calledvalue : nat; var s : storage) : return is
block{
  if calledvalue = 0 then failwith("something wrong with fetched result!") else skip;
  distribution(calledvalue);
  s.current_result := calledvalue   
}with ((nil: list(operation)),s);


function main (const p : actions; const s : storage) : return is
case p of 
| GetResult(t) -> getResult(t,s)
| SetTargetdate(t) -> setTargetdate(t,s)
| AdminWithdrawal(t) -> adminwithdrawal(t,s)
| Withdrawal ->  withdrawal(s)
end