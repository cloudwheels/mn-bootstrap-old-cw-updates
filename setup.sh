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

ipAddressQt=""

########################################
# JSON RPC CALLS
########################################

rpccall() #id  #user #port #method #params 
{
    
    echo "rpc called with id $1, user $2, port $3, method $4, params $5"
    rpc=$(curl -s --user $2 --data-binary '''{"method": "'''$4'''","params": ['''$5'''],"id": "'''$1'''"}''' --header 'Content-Type: text/plain;' localhost:$3)
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
# set variables in this method tp define the rpc calls
getGenesisBlockhash()
{
    rpcid="getGenesisBlockhash"
    rpcMethod="getblockhash"
    rpcParams=0
}
#call the method
getGenesisBlockhash 
#call rpccall()
rpccall $rpcid $rpcUser $rpcPortCore $rpcMethod $rpcParams
echo "The genesis blockhash is: $rpc"




# mn setup variables
payoutAddress=""
collateralAddress=""
ownerKeyAddr=""
votingKeyAddr=""

masternodeOutputs="masternode outputs"
masternodeOutputsResult=""
collateralHash=""
collateralIndex=""



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