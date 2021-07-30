type contract_storage is record [
    addroracle : address;
    ybalance : tez;
    nbalance : tez;
    register : map(address, bool);
    stake : map(address, tez);
    tdate : timestamp;
    account : big_map(address,tez);
    p_ybalance : tez;
    p_nbalance : tez;
    p_tdate : timestamp;
    p_iscancelled: bool;
    p_isdistributed: bool;
]

type result_storage is timestamp * int

const one_day : int = 86_400;
const one_hour : int = 3_600;
const half_an_hour : int = 1_800;

type action is
| AdminWithdrawal of (tez)  //
| Bet of (bool)
| CheckResult of (address) //
| CheckTimePointBet
| Distribution of (timestamp)  //
| Sum_map of (big_map)
| ValidationAmount
| Withdrawal

function adminwithdrawal (const amt : tez) : list(operation) * contract_storage is
block {

} with s

function checktimepointbet (var s : contract_storage) : contract_storage is 
block {
  if Tezos.now > s.tdate - one_day + one_hour then failwith ("it has passed deadline for the next bet!");
  if Tezos.now < s.tdate - one_day then failwith ("the next round is not open yet!");
} with s

function checkresult (const addr : address) : int is
block {
  ////////
} with (result_int)

function distribution (const nextdate : timestamp; var s : contract_storage) : contract_storage is
block {
  validationamount(s);
  if nextdate < s.tdate then failwith ("init next bet failed as next date is smaller than current target date");
  if Tezos.sender =/= Tezos.source then failwith ("Only can be executed by the contract originator");
  if Tezos.now < s.tdate + half_an_hour then failwith ("The distribution function runs too early");
  if Tezos.now > s.tdate + one_day then failwith ("Too late to run the distribution function");
  if nextdate =/= s.tdate then failwith ("nextdate is the next one in the oracle list");

  if s.ybalance / s.nbalance < 100n or s.nbalance / s.ybalance < 100n then 
  block {
     for key -> value in map s.stake block {
       case s.p_account[key] of
         Some(pattern) -> s.p_account[key] := s.p_account[key] + s.stake[key]
       | None -> s.p_account[key] := s.stake[key]
       s.p_iscancelled := True;
     }
  }
  else 
  block {
  /////////////////
  s.p_iscancelled := False;
  }
  s.p_tdate := s.tdate; 
  s.tdate := nextdate;
  s.ybalance := 0tez;
  s.nbalance := 0tez;
  s.register := map[];
  s.stake := map[];

} with s

function bet (var s : contract_storage; const betbool : bool) : contract_storage is
block {
  validationamount(s);
  checktimepointbet(s);
  if amount < 1.0tez then failwith ("the amount must be larger than 1 tezos");
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

function validationamount (var s : contract_storage) : contract_storage is 
block {
  if Tezos.balance < s.nbalance + s.ybalance + sum_map(s.account) then failwith ("Cannot make any operation as the balance of the contract is smaller than the pool");
}

function withdrawal ( var s : contract_storage) : list(operation) * contract_storage is
block {
  validationamount(s);
  const ops : list(operation) = list [];
  case s.p_account[Tezos.sender] of
    Some(pattern) -> block {
      const op : operation = Tezos.transaction (unit, amounts, execontract);
      ops := list[op];
      s.p_account := Big_map.update(Tezos.sender, None, s.p_account);
    }
  | None -> failwith ("Your address is not in the pool");
  end; 
} with (ops,s)


function main (const p : action ; const s : contract_storage) : (list(operation) * contract_storage) is
  block {
      const receiver : contract (unit) = 
      case (Tezos.get_contract_opt (s.owner): option(contract(unit))) of 
        Some (contract) -> contract
      | None -> (failwith ("Not a contract") : (contract(unit)))
      end;
    const payoutOperation : operation = Tezos.transaction (unit, amount, receiver);
    const operations : list(operation) = list [payoutOperation]    
  } with case p of 
  | AdminWithdrawal
  | Bet(n) -> ((nil : list(operation)), addCreditor(n.0,n.1,n.2,n.3,s))
  | Distribution(n) -> ((nil : list(operation)), approve(n.0, n.1, s))
  | Withdrawal(n) ->  ((operations : list(operation)), modifyOwnership(n.0,n.1,n.2,s))
  | CheckPoint -> ((nil : list(operation)), checkPoint(s))
 end
