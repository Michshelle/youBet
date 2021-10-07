#Oracle itself init
./tezos-client originate contract contract_oracle transferring 0 from alice running oracle.tz --init 'Pair (Pair (Pair <Address> "1900-01-01") 0 "1900-01-01") 0 0' --burn-cap 0.5
##<Address> need to be filled with the one which later has the right to update values of the oracle contract.

#Pool manager init
./tezos-client originate contract pool_manager transferring 5 from alice running test_pool_manager.tz --init '(Pair (Pair (Pair (Pair {} 0) (Pair "1990-01-01" "1990-01-01")) (Pair (Pair 0 <Address>) (Pair {} {} ))) (Pair "2021-08-04" 0))' --burn-cap 1.5
##<Address> the address of the oracle contract.

#Running Oracle to get prices for current trading day and previous trading day
python ./scripts/updateOracleData/updateOracle.py

#Set target date to bet for pool manager
./tezos-client transfer 0 from alice to pool_manager --entrypoint 'setTargetdate' -arg '"YYYY-MM-DD"' --burn-cap 0.02
##Change YYYY-MM-DD for to the specific date for betting

#Bet
./tezos-client transfer 3 from <tz account alias> to pool_manager --entrypoint 'bet' -arg 'bool_bet' --burn-cap 0.02
##change <tz account alias> to the tz account you aliased, bool_bet is True or False

#GetResult
./tezos-client transfer 0 from alice to pool_manager --entrypoint 'getResult' -arg '"YYYY-MM-DD"' --burn-cap 0.02
##YYYY-MM-DD is the target date to run

#Withdrawal
./tezos-client transfer 0 from <tz account alias> to pool_manager --entrypoint 'withdrawal'  --burn-cap 0.02
##change <tz account alias> to the tz account you aliased

