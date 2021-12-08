#!/usr/bin/env bash

echo "starting dfs daemons"

hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ start namenode
hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ start secondarynamenode
hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ start datanode

# eof