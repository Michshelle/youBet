type storage is 
record [
    current_result : nat;
    target_date : string;
    oracleAddress : address;
]
type return is list(operation) * storage
type actions is 
| GetResult of string
| SetTargetdate of string
| HandleCallback of nat

function getResult(const tdate: string; var s : storage) : return is 
block{
    if tdate =/= s.target_date then failwith ("Not the target date to run") else skip;
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
    const resp : list(operation) = list [Tezos.transaction(param,0mutez,oracle)];
} with (resp,s);

function setTargetdate(const ndate : string; var s : storage) : return is 
block {
    s.target_date := ndate;
} with ((nil: list(operation)),s)

function handleCallback(const calledvalue : nat; var s : storage) : return is
block{

    //进pool_organ分配。
    s.current_result := calledvalue;  
    
}with ((nil: list(operation)),s);


function main (const p : actions; const s : storage) : return is
case p of 
| GetResult(t) -> getResult(t,s)
| SetTargetdate(t) -> setTargetdate(t,s)
| HandleCallback(n) -> handleCallback(n,s)
end
