#!/usr/bin/env bash

echo "stopping yarn daemons"

yarn-daemon.sh --config ~/hadoop/etc/hadoop/ stop resourcemanager
yarn-daemon.sh --config ~/hadoop/etc/hadoop/ stop nodemanager

# eof