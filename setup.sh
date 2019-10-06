#!/bin/sh

## start main
main()
{
# requires jq to process json results
# requires dig from dns utils to lookup IP address
# requires python, docker
# TODO check for pre-requisites

current_date_time="`date +%Y%m%d%H%M%S`"
logfilename="log-$current_date_time.md"
logfilepath="./logs/"
logfile=$logfilepath$logfilename

echo "# Log $current_date_time\n\n" >> $logfile

#SET NETWORK NAME HERE
devnetName="devnet-dashevo1" 

echo "Set up devnet $devnetName\n\n" >> $logfile

#Cleanup existing

#STOP and REMOVE containers and network
sudo ./mn-bootstrap.sh $devnetName down #&&
sudo ./mn-bootstrap.sh $devnetName rm -fv #&&

# GET RID OF DATA
sudo rm -rf ./data/core-$devnetName
sudo rm -rf ./data/qt-$devnetName

# COMPOSE NETWORK
sudo ./mn-bootstrap.sh $devnetName up -d

###
# ONCE SERVICES ARE STARTED WE NEED TO WAIT FOR THE WALLET TO BE READY (POPULATE ADDRESSES)
###


# network variables
#TODO
# Get the Docker bridge IP address of the core server to be used as a MN 
# The QT server can then be started adding this as a node

serviceCore="$devnetName""_core_1"
serviceQT="$devnetName""_qt_1"

ipAddressCore=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mn-bootstrap-$serviceCore)
echo "MN Core server docker bridge IP: $ipAddressCore"
ipAddressQt=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mn-bootstrap-$serviceQT)
echo "QT Wallet server docker bridge IP: $ipAddressQt"
portCore=20001
portExternal=20001
externalIPAddr=$(dig +short myip.opendns.com @resolver1.opendns.com)
ipAndPortExternal=$externalIPAddr:$portExternal ## MAY BE REASON FOR ERROR 16 BAD TX ADDRESS
echo "externalIPAddr: $externalIPAddr"
echo "portExternal: $portExternal"
echo "externalIPAddr: $externalIPAddr"

operatorReward=0

########################################
# JSON RPC CALLS
########################################

rpccall() #id  #user #port #method #params #debug
{
# echo "rpc called with id $1, user $2, port $3, method $4, params $5"
rpcrequest="curl -s --user $2 --data-binary '''
{     
    \"method\": \"$4\",
    \"params\": [$5],
    \"id\": \"$1\"
}''' \\
--header 'Content-Type: text/plain;' localhost:$3"

## TODO : Fix passing a debug parameter
#if [ $6 -eq 1 ] # debug
#then
#   ...
#else
#   ...
#fi

echo "RPC Request\n\`\`\`shell\n$rpcrequest\n\`\`\`\n\n" >> $logfile

#send command (eval)
rpcresponse=$( eval $rpcrequest)
#echo "rpcresponse:"
#echo "$rpcresponse"  

echo "RPC Response\n\`\`\`shell\n$rpcresponse\n\`\`\`\n\n" >> $logfile

# parse the result
rpcresult=$( echo $rpcresponse | jq -r '.result')
#echo "rpcresult:"
#echo "$rpcresult"

echo "RPC Result\n\`\`\`shell\n$rpcresult\n\`\`\`\n\n" >> $logfile

## TODO : handle errors 
# parse error
rpcerror=$( echo $rpcresponse | jq -r '.error')
#echo "rpcerror:"
#echo "$rpcerror"

echo "RPC Error\n\`\`\`shell\n$rpcerror\n\`\`\`\n\n" >> $logfile

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
#echo "The genesis blockhash is: $rpcresult"



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


echo "Atteping to Set up addresses in the QT Wallet..."
getNewAddress

#loop until wallet ready to create addresses
while [ -z "$testAddress" ] || [ "$testAddress" = "null" ]
do
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
testAddress=$rpcresult
echo "testAddress=$testAddress waiting for wallet..."
sleep 3
done

echo "testAddress=$testAddress"


##
# FIRST CONNECT NODES TO MAINTAIN SYNC IN THE CHAINS
# ADDNODE CORE TO WALLET AS PEER 
##

echo "add core service $ipAddressCore:$portCore as peer to wallet"
addNode() #node #"add"
{
    rpcid="addNode"
    rpcMethod="addnode"
    rpcParams="\"$1\",\"$2\""
}

addNode "$ipAddressCore:$portCore" "add"
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 
echo "$rpcid result $rpcresult"

echo "wait 3 seconds and check for node as peer"

getPeerInfo()
{
    rpcid="getPeerInfo"
    rpcMethod="getpeerinfo"
    rpcParams=""
}

getPeerInfo
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 
echo "$rpcid result $rpcresult"


# continue setting up addresses
echo "continue setting up addresses"
getNewAddress
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
payoutAddress=$rpcresult
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
collateralAddress=$rpcresult
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
ownerKeyAddress=$rpcresult
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
votingKeyAddress=$rpcresult


echo "payoutAddress=$payoutAddress"
echo "collateralAddress=$collateralAddress"
echo "ownerKeyAddress=$ownerKeyAddress"
echo "votingKeyAddress=$votingKeyAddress"
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
########################
# TODO : CHANGE BACK TO 500
#######################
generate 500
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

# The result will be an array of all the block hashes
# TODO check / explain this  
echo "mining result $rpcresult"


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
echo "block count in wallet $rpcresult"
rpccall $rpcid $rpcUser $rpcPortCore $rpcMethod $rpcParams
echo "block count in core $rpcresult"


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
echo "$rpcid result $rpcresult"

echo "sending 100 tDash to the payoutAddress $payoutAddress - needs a balance tp cover tx fees"

sendToAddress $payoutAddress 100
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 
echo "$rpcid result $rpcresult"

# Mine this transaction
# Must have at least ?8 confirmations, TODO: check
# So mine 10...
echo "Mine these transactions. Generate 10 blocks to ensure sufficient confirmations...."
generate 10
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
# The result will be an array of all the block hashes
echo "mining result $rpcresult"


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
echo "$rpcid result $rpcresult"


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
 echo "masternode outputs $rpcresult"


 #####
 # If you run this over and over it doesn't (?always)create multiple 1000 balances. Why?
 # Sends the 1000 from exiting collateral address??
 # TODO: set sending address for the transaction
 #####
# result is simalar to: {"04149b8efeacfc79d68bb15c7cd6fa3be27a47176d77ccbf466391830ef3e200": "1"}

 
collateralHash=$( echo  $rpcresult | cut -d ":" -f 1 | cut -d "{" -f 2  | xargs )
collateralIndex=$( echo  $rpcresult | cut -d ":" -f 2 | cut -d "}" -f 1  | xargs )

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
 echo "bls generate result $rpcresult"

 masternodeblsprivkey=$( echo $rpcresult  | jq -r '.secret' ) 
 masternodeblspublickey=$( echo $rpcresult  | jq -r '.public' )

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
# collateralIndex = 1
######
## RENAME masternodeblspublickey as operatorPubKey

###
#
#  USE A PUBLIC IP !!!!! 
# ?MAY WORK WITH A 0    
###




echo "Prepare a ProRegTx transaction"
echo 
echo "Inputs for ProRegTx: "
echo "collateralHash: $collateralHash"
echo "collateralIndex: $collateralIndex"
echo "ipAndPort: $ipAndPortExternal"
echo "ownerKeyAddress: $ownerKeyAddress"
echo "operatorPubKey: $operatorPubKey"
echo "votingKeyAddress: $votingKeyAddress"
echo "operatorReward: $operatorReward"
echo "payoutAddress: $payoutAddress"

protxRegisterPrepare() 
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
    rpcid="protxRegisterPrepare"
    rpcMethod="protx"
    rpcParams="\"$1\",\"$2\",$3,\"$4\",\"$5\",\"$6\",\"$7\",$8,\"$9\""
}



protxRegisterPrepare "register_prepare" $collateralHash $collateralIndex $ipAndPortExternal $ownerKeyAddress $masternodeblspublickey $votingKeyAddress $operatorReward $payoutAddress
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
echo "protx register_prepare result $rpcresult"
echo
protxHash=$( echo $rpcresult  | jq -r '.tx' )
# collateralAddress should match the funded address above
collateralAddressCheck=$( echo $rpcresult  | jq -r '.collateralAddress' )
signMessage=$( echo $rpcresult  | jq -r '.signMessage' )

echo "protx prepare variables:"
echo "protxHash: $protxHash"
echo "collateralAddressCheck: $collateralAddressCheck"
echo "signMessage: $signMessage"


# Sign the ProRegTx transaction

echo "Sign the ProRegTx transaction"

# Get private key of collateralAddress 

echo "! Instructions imply that we need to get the private key of collateralAddress $collateralAddress"

# dumpprivkey() #address
# {   
#    rpcid="dumpprivkey"
#    rpcMethod="dumpprivkey"
#    rpcParams="\"$1\""
# }

# dumpprivkey $collateralAddress
# rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
# collateralAddressPrivateKey=$( echo $rpc)
# echo "dumpprivkey result $collateralAddressPrivateKey"

# echo "* SIGNING WITH THIS PRIVATE KEY CREATES ERROR code:-3,message:Invalid address *"
# echo "* SIGN WITH PUBLIC KEY / ADDRESS INSTEAD *"

# signmessage
echo "sign the protx message"
echo "signmessage collateralAddress signMessage"

signmessage() 
# "collateralAddressPrivateKey" / collateralAddress
# signMessage
{   
    rpcid="signmessage"
    rpcMethod="signmessage"
    rpcParams="\"$1\",\"$2\""
}
signmessage $collateralAddress $signMessage
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams

signedMessageHash=$( echo $rpcresult)
echo "signedMessageHash result $signedMessageHash"


# Submit the signed message

echo "Submit the signed message"

protxRegisterSubmit() 
# "register_prepare"
# protxHash
# signedMessageHash

{   
    rpcid="protxRegisterSubmit"
    rpcMethod="protx"
    rpcParams="\"$1\",\"$2\",\"$3\""
}



protxRegisterSubmit "register_submit" $protxHash $signedMessageHash 
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams 

#an array??? (only if run mutlple times or by coincience of mining  rewards) 
# - split result and use fuirst suitable
echo "protxRegisterSubmit result $rpcresult"

echo "STUCK HERE - gives the error bad-protx-addr (code 16)"

echo "WORKS WHEN USING AND EXTERNAL IP ADDRESS - SEE NOTES"

echo "THE TRANSACTION NOW NEEDS TO BE MINED TO COMMIT THE PROTX TO THE BLOCKCHAIN"
echo "Mining protx...."
generate 1
rpccall $rpcid $rpcUser $rpcPortQt $rpcMethod $rpcParams
# The result will be an array of all the block hashes
echo "mining result $rpcresult"


echo "ENTER THE MASTERNODE INFORMATION ON THE CORE SERVER AFTER THIS SO THEY ARE IN SYNC:"
echo
echo "masternode=1"
echo "masternodeblsprivkey=$masternodeblsprivkey"
echo "externalip=$ipAndPortExternal"
echo 

echo "MASTERNODE WILL THEN BE SETUP BUT UNABLE TO CONNECT ON EXTERNAL IP"
echo "ALSO NEED TO UPDATE BINDING TO EXTERNAL IP"



######################################
# END MAIN METHOD AND RUN CONFIRMATION
######################################
} # end main

while true; do
    read -p "WORK IN PROGRESS - 
SCRIPT DOES NOT CHECK FOR PRE_REQUISITES:
Python
Docker ^ version 17.04.0
Docker Compose
jq
dig (DNS Utils)
ARE YOU SURE YOU WANT TO CONTINUE (y/n)?" yn
    case $yn in
        [Yy]* ) main; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done