# Dash Evo Devnet Setup (Dockerised)

## Overview

### qt-wallet core node setup

### start wallet with addnode
~/dash-qt/dash-qt --devnet=dashevo1 --listen=0 --addnode=172.20.0.3:20001

`generate 500`

file | receiving addresses

label exiting address as `payoutAddress`

set up 3 further necessary addresses

new

- collateralAddress
- ownerKeyAddr
- votingKeyAddr

![set up addresses](2019-10-04-18-55-20.png)

send 1000 tDash to collateralAddress

mine another 10 blocks to confirm this transaction

`generate 10`



### What services?

Creates network & 8 containers

- sentinel
- core
- ipfs
- mongodb
- insight
- drive_api
- drive_sync
- dapi_core
- dapi_tx_filter_stream


## Installation

### Check / install prerequisites
- Python
- docker (version 17.04.0+)
- docker-compose '(pip install -U docker-compose)' 


### Clone and run the mn-bootstap repo

Starting from your home directory:

`cd ~`

Clone the dashevo/mn-bootstrap repo from github: 

`git clone https://github.com/dashevo/mn-bootstrap.git`

Change into the mn-bootstrap directory:

`cd mn-bootstrap`


### Start network and containers

*Using sudo in this case*

`sudo ./mn-bootstrap.sh {NETWORK_NAME} up -d`

`sudo ./mn-bootstrap.sh devnet-dashevo1 up -d`

Expected result:

> ```
> Creating network "mn-bootstrap-devnet-dashevo1_default" with the default driver
> Creating mn-bootstrap-devnet-dashevo1_sentinel_1      ... done
> Creating mn-bootstrap-devnet-dashevo1_core_1          ... done
> Creating mn-bootstrap-devnet-dashevo1_ipfs_1          ... done
> Creating mn-bootstrap-devnet-dashevo1_drive_mongodb_1 ... done
> Creating mn-bootstrap-devnet-dashevo1_insight_1       ... done
> Creating mn-bootstrap-devnet-dashevo1_drive_api_1             ... done
> Creating mn-bootstrap-devnet-dashevo1_drive_sync_1    ... done
> Creating mn-bootstrap-devnet-dashevo1_dapi_core_1             ... done
> Creating mn-bootstrap-devnet-dashevo1_dapi_tx_filter_stream_1 ... done
> ```


### Start bash shell on core machine

`docker exec -it <container name> /bin/bash`

Container name will be mn-bootstrap-{NETWORK_NAME}_core_1

`docker exec -it mn-bootstrap-devnet-dashevo1_core_1 /bin/bash`


### Install nano editor

`apt install nano`



## set up masternode

In the wallet



￼
`masternode outputs`

Prints masternode compatible outputs.

```
{
  "b48529863b1be9487ab21a56a38e131c0d4f17b29849fd8b62fb6ac6396a217d": "1"
}
```

`collateralHash`

`b48529863b1be9487ab21a56a38e131c0d4f17b29849fd8b62fb6ac6396a217d`

`collateralIndex`

`1`


### Generate a BLS key pair

> ***The private key is specified ON THE MASTERNODE itself***

***do this on the masternode

`bls generate`

`dash-cli bls generate`

```
{
  "secret": "69c1108906c6d9ae8f5770f131ff11ddb80f15f68d3db6b40dad1d8c19ceec6a",
  "public": "85c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b1"
}
```


### Add `masternodeblsprivkey` to `dash.conf`

`nano ~/.dashcore/dash.conf`

```
masternode=1
masternodeblsprivkey=69c1108906c6d9ae8f5770f131ff11ddb80f15f68d3db6b40dad1d8c19ceec6a
```

### Restart the masternode

```
~/.dashcore/dash-cli stop
# wait for shutdown approx 30 secs.
~/.dashcore/dashd
```
?Monitor with sentinel

Check .conf file after restart

`nano ~/.dashcore/dash.conf`

**!! THIS SEEMS TO PREVENT THE WALLET FROM CONNECTING AS A PEER **


### Prepare a ProRegTx transaction

> ***The private keys to the owner and fee source addresses must exist in the wallet submitting the transaction to the network.***

***Do in the qt-wallet***

Arguments

```
protx register_prepare collateralHash collateralIndex ipAndPort ownerKeyAddr operatorPubKey votingKeyAddr operatorReward payoutAddress
```

- **`collateralHash`**

`b48529863b1be9487ab21a56a38e131c0d4f17b29849fd8b62fb6ac6396a217d`

- **`collateralIndex`**

`1`

- **`ipAndPort`**

*Same as used in addnode*
*Check hasn't changed after mn restart*

`172.20.0.3:20001`

- **`ownerKeyAddr`**

*The new Dash address generated above for the owner/voting address*

`yezaWmyhHjEZGiL1SRRboYhi3sex5y86s2`

- **`operatorPubKey`**

*The BLS **public key** generated above* 

`85c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b1`

- **`votingKeyAddr`**

*The new Dash address generated above*

`yRh8koGafRjhKNVCGRHr18Pcf1Lw4kgydC`

- **`operatorReward`**

*The percentage of the block reward allocated to the operator as payment*

`0`

- **`payoutAddress`**

*A new or existing Dash address to receive the owner’s masternode rewards*

`yQ6k2gf8BPcHBcyjfGuvzjAXCPwUETTnsx`


```
protx register_prepare b48529863b1be9487ab21a56a38e131c0d4f17b29849fd8b62fb6ac6396a217d 1 172.20.0.3:20001 yezaWmyhHjEZGiL1SRRboYhi3sex5y86s2 85c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b1 yRh8koGafRjhKNVCGRHr18Pcf1Lw4kgydC 0 yQ6k2gf8BPcHBcyjfGuvzjAXCPwUETTnsx
```

result:

```
{
  "tx": "0300010001407140473922bab1f86ca08ac937b9de5124ee20c956484aedd3c33babd2037d0100000000feffffff0121ceed902e0000001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88ac00000000d10100000000007d216a39c66afb628bfd4998b2174f0d1c138ea3561ab27a48e91b3b862985b40100000000000000000000000000ffffac1400034e21ccd8e294df3760d288a9fc9238f4e22aadc1066385c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b13af2ad3904531e4e5e05e8f403ae0229f735915700001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88acd818f1d6ccf023fd6a51329832ff148530ddb8df62476633dd15ba8e6271d35900",
  "collateralAddress": "yM2WrFGJMk5YSVyKmGhPXKhE43vmF7Pv2B",
  "signMessage": "yQ6k2gf8BPcHBcyjfGuvzjAXCPwUETTnsx|0|yezaWmyhHjEZGiL1SRRboYhi3sex5y86s2|yRh8koGafRjhKNVCGRHr18Pcf1Lw4kgydC|674537d5dd85b1666f1bf84c7d2c214c830bd609e2e7c7f9920621b8c0c27005"
}
```

### Sign the ProRegTx transaction

Can be done offline (so wallet or masternode???)

We will now sign the content of the signMessage field using the **private key** for the collateral address as specified in collateralAddress.

#### Get the private key of the collateral address in the wallet

`dumpprivkey “address”`

`dumpprivkey yM2WrFGJMk5YSVyKmGhPXKhE43vmF7Pv2B`

`cUa3Ahv5VeyMdr6dpFpKB3YUmycXZAeqyEU9Kjaip3mzGLkFnRyK`

#### Sign

`signmessage collateralAddress signMessage`

`signmessage cUa3Ahv5VeyMdr6dpFpKB3YUmycXZAeqyEU9Kjaip3mzGLkFnRyK yQ6k2gf8BPcHBcyjfGuvzjAXCPwUETTnsx|0|yezaWmyhHjEZGiL1SRRboYhi3sex5y86s2|yRh8koGafRjhKNVCGRHr18Pcf1Lw4kgydC|674537d5dd85b1666f1bf84c7d2c214c830bd609e2e7c7f9920621b8c0c27005`

**Error!**

`Invalid address (code -3)`

***USE WALLET ADDRESS***

`signmessage yM2WrFGJMk5YSVyKmGhPXKhE43vmF7Pv2B yQ6k2gf8BPcHBcyjfGuvzjAXCPwUETTnsx|0|yezaWmyhHjEZGiL1SRRboYhi3sex5y86s2|yRh8koGafRjhKNVCGRHr18Pcf1Lw4kgydC|674537d5dd85b1666f1bf84c7d2c214c830bd609e2e7c7f9920621b8c0c27005`

result:

`IHduLGAuiYVbeI/Z+c7K5QITL3HdhHq5wYBaFjUbljNiZd+Kn9r94gjLXUoL0S1gFe+tKnBcbPwRHFGzw1KcBZY=`

### Submit the signed message
We will now submit the ProRegTx special transaction to the blockchain to register the masternode. This command must be sent from a Dash Core wallet holding a balance on either the feeSourceAddress or payoutAddress, since a standard transaction fee is involved. The command takes the following syntax:

i.e. Wallet - but not connected!!!

`protx register_submit tx sig`

tx: The serialized transaction previously returned in the tx output field from the protx register_prepare command
sig: The message signed with the collateral key from the signmessage command

`protx register_submit 0300010001407140473922bab1f86ca08ac937b9de5124ee20c956484aedd3c33babd2037d0100000000feffffff0121ceed902e0000001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88ac00000000d10100000000007d216a39c66afb628bfd4998b2174f0d1c138ea3561ab27a48e91b3b862985b40100000000000000000000000000ffffac1400034e21ccd8e294df3760d288a9fc9238f4e22aadc1066385c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b13af2ad3904531e4e5e05e8f403ae0229f735915700001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88acd818f1d6ccf023fd6a51329832ff148530ddb8df62476633dd15ba8e6271d35900 IHduLGAuiYVbeI/Z+c7K5QITL3HdhHq5wYBaFjUbljNiZd+Kn9r94gjLXUoL0S1gFe+tKnBcbPwRHFGzw1KcBZY=`

**Error!**

`bad-protx-addr (code 16) (code -1)`

`protx register_submit 0300010001407140473922bab1f86ca08ac937b9de5124ee20c956484aedd3c33babd2037d0100000000feffffff0121ceed902e0000001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88ac00000000d10100000000007d216a39c66afb628bfd4998b2174f0d1c138ea3561ab27a48e91b3b862985b40100000000000000000000000000ffffac1400034e21ccd8e294df3760d288a9fc9238f4e22aadc1066385c263806ef7b03ecbe2e6dde55e9c2d523373f5bc77a71561e657167c9dacd6d06f422da88532a63a3f7cc8c36c41b13af2ad3904531e4e5e05e8f403ae0229f735915700001976a91429796ff78c0c75999fcbcf65d6bc1c1316245f2e88acd818f1d6ccf023fd6a51329832ff148530ddb8df62476633dd15ba8e6271d35900 IHduLGAuiYVbeI/Z+c7K5QITL3HdhHq5wYBaFjUbljNiZd+Kn9r94gjLXUoL0S1gFe+tKnBcbPwRHFGzw1KcBZY=`


## Utils

### Get core container IP address

```
sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mn-bootstrap-devnet-dashevo1_core_1
```
