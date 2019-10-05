# MN Bootstrap (cloudwheels)

This is a fork of [https://github.com/dashevo/mn-bootstrap](https://github.com/dashevo/mn-bootstrap). The [Orignal README is below](#original-readme)

## Purpose

Setup a basic containerised (Docker) Dash network as a LOCAL environment to develop / experiment with the Dash evolution platform.

The orignal repo is a bit out of date, particularly with the information on setting up a masternode (MN). A MN is required to run the Distributed API (DAPI).

### Disclaimer

***Experimental, personal, unstable and strictly for development purposes only (if at all)***

### Updates / Status

- This is currently very much WORK IN PROGRESS!
- So far I have:
    - Documented (roughly) my [inital experience at setting up a masternode](cloudwheels-adventures.md)
    - Made some changes to the Docker setup: mainly adding another Dash core service to the network to use as a wallet, so that the intial core can be set up as a masternode. This container is named "qt" after the core wallet, although it is running as a server.
    - started a [shell script](setup.sh) to (a) extend / modify the original wrapper around Docker compose and (b) script some of the masternode setup process using the available RPC api.



---

## Original README

## MN Bootstrap

### Pre-requisites to be Installed

* [Python](https://www.python.org/downloads/)
* [docker](https://docs.docker.com/engine/installation/) (version 17.04.0+)
* docker-compose (`pip install -U docker-compose`)

### Setup

0. Clone this repo & cd to the directory:

```
git clone git@github.com:dashevo/mn-bootstrap.git ./mn-bootstrap
cd mn-bootstrap
```

### Using mn-bootstrap.sh for regtest

mn-bootstrap provides a wrapper around docker-compose to make using different networks
and presets easier. It is called this way:

```bash
$ ./mn-bootstrap.sh <network> [preset] <compose_args...>
```

To bootstrap with regtest as network and latest preset use:

```bash
$ ./mn-bootstrap.sh regtest up -d
```

To bootstrap with regtest as network and specific preset use:

```bash
$ ./mn-bootstrap.sh regtest maithai up -d
```

The argument `-d` is is used to start everything in the background. User `logs`
to view the logs in the foreground:

```bash
$ ./mn-bootstrap.sh regtest logs
```

If you want to call dash-cli inside of the dashd container, you can use the `dash-cli.sh` wrapper

```bash
$ ./dash-cli.sh regtest getinfo
```

To shut down everything, use:

```bash
$ ./mn-bootstrap.sh regtest down
```

To delete all containers and node data, use:

```bash
$ ./mn-bootstrap.sh regtest rm -fv
# sudo is needed because docker will create volumes with different owner then your user
$ sudo rm -rf ./data/core-regtest
```

### Connecting mn-bootstrap to devnet

To connect mn-bootstrap to an existing devnet, you'll have to do some preparations first. You'll have to open the devnet
dashd port on your router, prepare a MN privkey and edit `devnet-dashevo1.env`. It is also recommended to have a dash-qt
node connected to the same devnet to make working with it easier.

1. Connect a normal dash-qt wallet to the devnet

Use the example configuration provided in `examples/dash-qt-devnet`.

It is important that you use a version of dash-qt that is compatible to the used devnet.
If you connect to a public devnet, use the latest released version (>=0.12.3, which is not released at time of writing)
or compile it by yourself from [dashpay/dash](https://github.com/dashpay/dash) (branch develop).

For the private dashevo devnet, use a self compiled binary from [dashevo/dash](https://github.com/dashevo/dash)

2. Fund the MN collateral

Use your Qt-Wallet to generate an address and send 1000 Dash to it using the Devnet Faucet
(please ask in Slack for the URL of the faucet as we don't have a final URL atm)

After confirmation of the TX, use `masternode outputs` (from debug console or dash-cli) to find the collateral TX and index

3. Generate a MN privkey in the Qt-Wallet

Use the debug console or dash-cli to generate a MN privkey by calling `masternode genprivkey`

4. Update `networks/devnet-dashevo1.env` and `masternodes.conf`

Put the generated MN privkey and collateral TX+index into `masternodes.conf` of your Qt-Wallet. Restart your Qt-Wallet afterwards.

Now put the MN privkey into `networks/devnet-dashevo1.env` and update your public/external IP as well.

5. Start up mn-bootstrap

Use the instructions from `Using mn-bootstrap.sh for regtest` but with `devnet-dashevo1` as network parameter

6. Start the MN from the Qt-Wallet

Use the debug console or dash-cli to call `masternode start-missing`

7. Done

Now watch the logs of mn-bootstrap to see if the MN is working properly.
