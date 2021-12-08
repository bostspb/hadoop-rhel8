#!/usr/bin/env bash

echo "stopping dfs daemons"

hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ stop namenode
hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ stop secondarynamenode
hadoop-daemon.sh --config ~/hadoop/etc/hadoop/ stop datanode

# eof
