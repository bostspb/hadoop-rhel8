#!/usr/bin/env bash

echo "starting yarn daemons"

yarn-daemon.sh --config ~/hadoop/etc/hadoop/ start resourcemanager
yarn-daemon.sh --config ~/hadoop/etc/hadoop/ start nodemanager

# eof
