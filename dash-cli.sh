#!/usr/bin/env bash

NETWORK=$1
shift 1

exec ./mn-bootstrap.sh $NETWORK exec core dash-cli "$@"

