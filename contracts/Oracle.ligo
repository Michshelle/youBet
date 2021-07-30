type storage is 
record [    
    currentd : string;
    currentq : nat;
    previousd : string;
    previousq : nat;
    addr : address;
    result : nat;
    ]
type return is list(operation) * storage;
type actions is
| GetData of contract(nat)
| Update of nat * string * nat * string

function getData(const u : contract(nat); const s : storage) : return is
(list[Tezos.transaction(s.result, 0mutez, u)], s)

function update(const current_quote : nat; const current_day : string; const previous_quote : nat; const previous_day : string; var s : storage) : return is
block {
    if Tezos.sender =/= (s.addr) then failwith("Not allowed") else skip; 
    s.currentq := current_quote;
    s.currentd := current_day;
    s.previousq := previous_quote;
    s.previousd := previous_day;
    if current_quote > previous_quote then s.result := 2n else s.result := 1n
} with ((nil : list(operation)), s)

function main(const a : actions; const s : storage) : return is
case a of
| GetData(u) -> getData(u,s)
| Update(v) -> update(v.0,v.1,v.2,v.3,s)
end 