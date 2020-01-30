#!/usr/bin/env bash

set -euxo pipefail

source /etc/mdsd.d/mdsd

mdsd $MDSD_OPTIONS
