#!/bin/sh

## start main
main()
{

# requires jq to process json results
# TODO check for pre-requisites


# network variables
#TODO
# Get the Docker bridge IP address of the core server to be used as a MN 
# The QT server can then be started adding this as a node

ipAddressCore=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mn-bootstrap-devnet-dashevo1_core_1)
echo "MN Core server docker bridge IP: $ipAddressCore"
portCore=20001
ipAndPort=$ipAddressCore:$portCore
ipAddressQt=""
operatorReward=0

########################################
# JSON RPC CALLS
########################################

rpccall() #id  #user #port #method #params #debug
{
## TODO : Fix passing a debug parameter
## TODO : handle errors  
## TODO : check actual message generated 
echo "rpc called with id $1, user $2, port $3, method $4, params $5"
#if [ $6 -eq 1 ] # debug
#then
#   rpc=$(curl -s --user $2 --data-binary '''{"method": "'''$4'''","params": ['''$5'''],"id": "'''$1'''"}''' --header 'Content-Type: text/plain;' localhost:$3)
#else
    rpc=$(curl -s --user $2 --data-binary '''{"method": "'''$4'''","params": ['''$5'''],"id": "'''$1'''"}''' --header 'Content-Type: text/plain;' localhost:$3 | jq -r '.result')
#fi
    
    
}

# rpc defaults

rpcUser="dashrpc:password"
rpcPortCore=20002
rpcPortQt=20012


# set these global varibles in a method
# the call rpccall to pass them as args
rpcMethod=""
rpcParams=""
rpcid=""

# e.g.
## set variables in this method tp define the rpc calls
getGenesisBlockhash()
{
    rpcid="getGenesisBlockhash"
    rpcMethod="getblockhash"
    rpcParams=0
}
## call the method
# getGenesisBlockhash 
## call rpccall()
#rpccall $rpcid $rpcUser $rpcPortCore $rpcMethod $rpcParams
#echo "The genesis blockhash is: $rpc"




# mn setup variables
payoutAddress=""
collateralAddress=""
ownerKeyAddress=""
votingKeyAddress=""
testAddress=""

masternodeOutputs="masternode outputs"
masternodeOutputsResult=""
collateralHash=""
collateralIndex=""

#####
# USING THE 'QT' WALLET
#####

###
# setup addresses
###
getNewAddress()
{
    rpcid="getNewAddress"
    rpcMethod="getnewaddress"
    rpcParams=""
}


echo "Setting up addresses in the QT Wallet..."
getNewAddress
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
payoutAddress=$rpc
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
collateralAddress=$rpc
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
ownerKeyAddress=$rpc
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
votingKeyAddress=$rpc
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
testAddress=$rpc

echo "payoutAddress=$payoutAddress"
echo "collateralAddress=$collateralAddress"
echo "ownerKeyAddress=$ownerKeyAddress"
echo "votingKeyAddress=$votingKeyAddress"
echo "testAddress=$testAddress"
echo

###
# mine some intial coin (tDash)
###

generate() #amount
{
    rpcid="generate"
    rpcMethod="generate"
    rpcParams=$1
}

echo "Mine some tDash"
echo "Because of no of conformations needed to get spendable balance, use mine 500"
generate 1
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

# The result will be an array of all the block hashes
# TODO check / explain this  
echo "mining result $rpc"


# Check Tx has synced across the network
getBlockCount()
{
    rpcid="getBlockCount"
    rpcMethod="getblockcount"
    rpcParams=""
}

echo "wait 5 seconds and see if network has synced..."
sleep 5
getBlockCount
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
echo "block count in wallet $rpc"
rpccall $rpcid $rpcUser $rpcPortCore $rpcMethod $rpcParams
echo "block count in core $rpc"


# Send 1000 tDash to $collateralAddress
echo "sending 1000 tDash to the collateralAddress $collateralAddress"
sendToAddress() #address #amount
{
    rpcid="sendToAddress"
    rpcMethod="sendtoaddress"
    rpcParams="\"$1\",$2"
}

sendToAddress $collateralAddress 1000
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 
echo "$rpcid result $rpc"

# Mine this transaction
# Must have at least ?8 confirmations, TODO: check
# So mine 10...
echo "Mining..."
generate 10
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
# The result will be an array of all the block hashes
echo "mining result $rpc"


# Show wallet balances

echo "List address balances"
listAddressBalances()
{
    rpcid="listAddressBalances"
    rpcMethod="listaddressbalances"
    rpcParams=""
}
listAddressBalances
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 
echo "$rpcid result $rpc"


# Get masternode outputs
echo "get masternode outputs"
echo "(hash & index of transactions valid for MN collateral)"   

masternode() #"outputs"
{   
    rpcid="masternode"
    rpcMethod="masternode"
    rpcParams="$1"
}

echo "get masternode outputs"
echo "(hash & index of transactions valid for MN collateral)"
masternode "\"outputs\""
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
 echo "masternode outputs $rpc"


 #####
 # If you run this over and over it doesn't (?always)create multiple 1000 balances. Why?
 # Sends the 1000 from exiting collateral address??
 # TODO: set sending address for the transaction
 #####
# result is simalar to: {"04149b8efeacfc79d68bb15c7cd6fa3be27a47176d77ccbf466391830ef3e200": "1"}

 
collateralHash=$( echo  $rpc | cut -d ":" -f 1 | cut -d "{" -f 2  | xargs )
collateralIndex=$( echo  $rpc | cut -d ":" -f 2 | cut -d "}" -f 1  | xargs )

echo "collateralHash: $collateralHash"
echo "collateralIndex:  $collateralIndex"


# Generate BLS key

######
# DOES THIS NEEDS TO BE DONE ON THE MASTERNODE ???
######

# for now, run  on the wallet

# Create a BLS secret/public key pair using bls generate
echo "Create a BLS secret/public key pair"
  
bls() #"generate"
{   
    rpcid="bls"
    rpcMethod="bls"
    rpcParams="$1"
}

bls "\"generate\""
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
 echo "bls generate result $rpc"

 masternodeblsprivkey=$( echo $rpc  | jq -r '.secret' ) 
 masternodeblspublickey=$( echo $rpc  | jq -r '.public' )

 echo "masternodeblsprivkey: $masternodeblsprivkey"
 echo "masternodeblspublickey: $masternodeblspublickey"

############
# TODO: add keys to the masternode server / update conf
#
# masternode=1
# masternodeblsprivkey=$masternodeblsprivkey
#
# also update public port ? to $ipAddressCore
# 
# RESTART MN
# ?Loses connection to network as peer?
############


# Prepare a ProRegTx transaction
# protx register_prepare collateralHash collateralIndex ipAndPort ownerKeyAddress operatorPubKey votingKeyAddress operatorReward payoutAddress


##TEMP UNTIL ARRAY OF COLLATERAL HASH SORTED
collateralIndex = 1
######
## RENAME masternodeblspublickey as operatorPubKey


echo "Prepare a ProRegTx transaction"
echo 
echo "Inputs for ProRegTx: "
echo "collateralHash: $collateralHash"
echo "collateralIndex: $collateralIndex"
echo "ipAndPort: $ipAndPort"
echo "ownerKeyAddress: $ownerKeyAddress"
echo "operatorPubKey: $operatorPubKey"
echo "votingKeyAddress: $votingKeyAddress"
echo "operatorReward: $operatorReward"
echo "payoutAddress: $payoutAddress"

protx() 
# "register_prepare"
# collateralHash
# collateralIndex
# ipAndPort
# ownerKeyAddress
# operatorPubKey
# votingKeyAddress
# operatorReward
# payoutAddress
{   
    rpcid="protx"
    rpcMethod="protx"
    rpcParams="\"$1\",\"$2\",$3,$4,\"$5\",\"$6\",\"$7\",$8,\"$9\""
}



protx "register_prepare" $collateralHash 1 $ipAndPort $ownerKeyAddress $masternodeblspublickey $votingKeyAddress $operatorReward $payoutAddress
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
 echo "protx register_prepare result $rpc"














######################################
# END MAIN METHOD AND RUN CONFIRMATION
######################################
} # end main

while true; do
    read -p "**WORK IN PROGRESS - ARE YOU SURE YOU WANT TO CONTINUE (y/n)? **" yn
    case $yn in
        [Yy]* ) main; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done