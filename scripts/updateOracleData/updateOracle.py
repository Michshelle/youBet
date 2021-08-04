import sys
import subprocess
import rqdatac as rq

#the server needs to apply for rqdata license at outset
rq.init() 

#Fetch data from API____Start
current_date = rq.get_latest_trading_date()
previous_date = rq.get_previous_trading_date(rq.get_latest_trading_date())
df_data = rq.get_price('000001.XSHG',end_date=current_date,start_date=previous_date) #Shanghai Securities Composite Index
if len(df_data) != 2:
    sys.exit()
else:
    pass
sm_df_data = df_data['close']
current_quote = sm_df_data.loc["000001.XSHG",current_date.strftime("%Y-%m-%d")]
previous_quote = sm_df_data.loc["000001.XSHG",previous_date.strftime("%Y-%m-%d")]
#Fetch data from API____End

#remove decimal places and stringify
str_amplify_currentq = str(int(current_quote * 1000000)) 
str_amplify_previousq = str(int(previous_quote * 1000000))
#stringify datetime to timestamp for cmdline input
str_current_date = "\"" + current_date.strftime("%Y-%m-%d") + "\""
str_previous_date = "\"" + previous_date.strftime("%Y-%m-%d") + "\""

#Apply to smartpy to update value may seem more elegant, however due to limited server capacity it is better to just opt to cmdline.
str_command = "/Users/mich/tezos/tezos-client transfer 0 from alice to contract_oracle --entrypoint update --arg '(Pair (Pair " + str_amplify_currentq +" "+ str_current_date + ") (Pair " + str_amplify_previousq +" " + str_previous_date + "))' --burn-cap 0.5"
subprocess.run(str_command, shell=True)