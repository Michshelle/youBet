type storage is record[
    latestoracleAddress : address;
    previousoracleAddress : address;
    l_price : timestamp * nat;
    p_price : timestamp * nat;
]

type return is list(operation) * storage

type actions is
| GetCurrentData of unit
| GetPreviousData of unit
| HandleLatestCallback of nat
| HandlePreviousCallback of nat
| GetResult of bool

function getcurrentData(const s : storage) : return is
block {
    var loracle : contract(contract(nat)) := nil;

    case (Tezos.get_entrypoint_opt("%getPrice", s.latestoracleAddress) : option(contract(contract(nat)))) of
    | None -> failwith("Oracle not found")
    | Some(c) -> loracle := c
    end;

    var param : contract(nat) := nil;

    case (Tezos.get_entrypoint_opt("%handlelatestCallback", Tezos.self_address) : option(contract(nat))) of
    | None -> failwith("Callback function not found")
    | Some(p) -> param := p
    end;

    const response : list(operation) = list [Tezos.transaction(param, 0mutez, loracle)]
} with (response, s)

function getpreviousData(const s : storage) : return is
block {
    var poracle : contract(contract(nat)) := nil;

    case (Tezos.get_entrypoint_opt("%getPrice", s.previousoracleAddress) : option(contract(contract(nat)))) of
    | None -> failwith("Oracle not found")
    | Some(c) -> poracle := c
    end;

    var param : contract(nat) := nil;

    case (Tezos.get_entrypoint_opt("%handlepreviousCallback", Tezos.self_address) : option(contract(nat))) of
    | None -> failwith("Callback function not found")
    | Some(p) -> param := p
    end;

    const response : list(operation) = list [Tezos.transaction(param, 0mutez, poracle)]
} with (response, s)

function handlelatestCallback(const price : nat; const s : storage) : return is
block {
    s.l_price := price;
} with ((nil : list(operation)), s)

function handlepreviousCallback(const price : nat; const s : storage) : return is
block {
    s.p_price := price;
} with ((nil : list(operation)), s)

function getData(const u : contract(nat); const s : storage) : return is 
block {
    var result : nat := 2n;
    getcurrentData(s);
    getpreviousData(s);
    if s.l_price > s.p_price then 
      result := 1n
    else 
      result := 0n;

    if result = 2n then failwith("Comparison not working") else skip;

} with (list[Tezos.transaction(result, 0mutez, u)], s)

function main(const a : actions; const s : storage) : return is
case a of
| GetData -> getData(s)
end