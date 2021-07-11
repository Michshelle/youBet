type storage is (nat * timestamp * address)

type return is list(operation) * storage;

type update is 
| Timestamp of timestamp
| Store of nat

type actions is
| GetPrice of contract(nat)
| Update of update

function getPrice(const u : contract(nat); const s : storage) : return is
(list[Tezos.transaction(s.0, 0mutez, u)], s)

function update(const price_value : update; var s : storage) : return is
block {
    if Tezos.sender =/= (s.2) then failwith("Not allowed") else skip; 
    case price_value of 
    | Timestamp(tm) -> s.1 := tm
    | Store(n) -> s.0 := n
    end;
} with ((nil : list(operation)), s)

function main(const a : actions; const s : storage) : return is
case a of
| GetPrice(u) -> getPrice(u,s)
| Update(v) -> update(v,s)
end 