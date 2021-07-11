type contract_storage is record [
    ybalance : tez;
    nbalance : tez;
    register : map(address, bool);
    stake : map(address, tez);
    tdate : timestamp;
    p_account : big_map(address,tez);
    p_ybalance : tez;
    p_nbalance : tez;
    p_register : map(address, bool);
    p_stake : map(address, tez);
    p_tdate : timestamp;
    p_winner : string;
    p_iscancelled: bool;
    p_isdistributed: bool;
]

const one_day : int = 86_400;
const one_hour : int = 3_600;
const half_an_hour : int = 1_800;

type action is
| AdminWithdrawal of (tez)  //
| Bet of (bool)
| CheckResult  //
| CheckTimePointBet
| Distribution of (timestamp)  //
| QueryDateAvailability of (timestamp)   //
| Sum_map of (big_map)
| ValidationAmount
| ValidationAmountAdmin
| Withdrawal
| ThisShouldNotExist of (tez * tez * map * map * timestamp)

function adminwithdrawal () : list(operation) * contract_storage is
block {

} with s


function checktimepointbet (var s : contract_storage) : contract_storage is 
block {
  if Tezos.now > s.tdate - one_day + one_hour then failwith ("it has passed deadline for the next bet!");
  if Tezos.now < s.tdate - one_day then failwith ("the next round is not open yet!");
} with s


function querydateavailability (var currentdate : timestamp) : timestamp is
block {
  //////////
} with (taildate)

function checkresult (var s : contract_storage) : s is
block {
  ////////
} with (s)

function distribution (const nextdate : timestamp; var s : contract_storage) : contract_storage is
block {
  validationamount(s);
  if nextdate < s.tdate then failwith ("init next bet failed as next date is smaller than current target date");
  if Tezos.sender =/= Tezos.source then failwith ("Only can be exec by the contract originator");
  if Tezos.now < s.tdate + half_an_hour then failwith ("The distribution function runs too early");
  if Tezos.now > s.tdate + one_day then failwith ("Too late to run the distribution function");

  const orcale_date : timestamp = querydateavailability(s.tdate);
  if nextdate =/= oracle_date then failwith ("nextdate is the next one in the oracle list");

  if s.ybalance / s.nbalance < 100n or s.ybalance / s.nbalance < 100n then 
  block {
     for key -> value in map s.stake block {
       case s.p_account[key] of
         Some(pattern) -> s.p_account[key] := s.p_account[key] + s.stake[key]
       | None -> s.p_account[key] := s.stake[key]
     }
     s.p_winner := "null";
  }
  else 
  block {
  /////////////////
  }
  s.p_ybalance := s.ybalance;
  s.p_nbalance := s.nbalance; 
  s.p_register := s.register;
  s.p_stake := s.stake; 
  s.p_tdate := s.tdate; 
  s.p_iscancelled := True;
  s.p_isdistributed := False;
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

function sum_map (var m : big_map (address, int)) : int is block {
  var int_total : int := 0;
  for key -> value in big_map m block {
    int_total := int_total + value
  }
} with (int_total)

function validationamount (var s : contract_storage) : contract_storage is 
block {
  if Tezos.balance < s.nbalance + s.ybalance + sum_map(s.p_account) then failwith ("Cannot make any operation as the balance of the contract is smaller than the pool");
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
  | Mint(n) -> ((nil : list(operation)), mint(n, s))
  | Burn(n) -> burn(n.0,n.1,n.2,s)
 end
