#!/bin/bash
HOST_IP=`ip addr show eth0 | grep "inet " | awk '{print $2}'|awk -F'/' '{print $1}'`
sed -i "s/<HOSTNAME>/${HOST_IP}/g" $HADOOP_HOME/etc/hadoop/core-site.xml 

$HADOOP_HOME/bin/hdfs namenode -format
$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode
$HADOOP_HOME/bin/hdfs --config $HADOOP_HOME/etc/hadoop/ datanode

