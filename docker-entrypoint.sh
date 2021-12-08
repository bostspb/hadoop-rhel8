#!/bin/bash

if [ ! -d "/tmp/hadoop-hduser/dfs/name" ]; then
        $HADOOP_HOME/bin/hdfs namenode -format
fi

function finish {
    $HADOOP_HOME/sbin/stop-dfs.sh
    $HADOOP_HOME/sbin/stop-yarn.sh
    cat /dev/null >  $AIRFLOW_HOME/airflow-webserver.pid
    echo 'Bye, bye!'
}

trap finish SIGTERM
trap finish SIGINT
trap finish EXIT

$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

hdfs dfs -mkdir -p /tmp /logs /user/hduser /user/hive/warehouse
hdfs dfs -chmod +w /tmp /logs /user/hduser /user/hive/warehouse

schematool -initSchema -dbType postgres
hive --service hiveserver2 &
hive --service metastore &

airflow initdb
airflow variables -i /home/hduser/airflow_variables.dev.json
airflow connections -a --conn_id spark_default --conn_extra '{"deploy-mode": "client"}' --conn_type spark --conn_host local
airflow connections -a --conn_id hiveserver2_default --conn_type hiveserver2 --conn_host localhost --conn_port=10000

airflow webserver >/dev/null &
airflow scheduler

#tail -f /dev/null
