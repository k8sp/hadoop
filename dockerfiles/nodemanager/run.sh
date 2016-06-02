#!/bin/bash
HOST_IP=`ip addr show eth0 | grep "inet " | awk '{print $2}'|awk -F'/' '{print $1}'`
sed -i "s/<HOSTNAME>/${HOST_IP}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml 
sed -i "s/<RM_HOSTNAME>/${RM_HOSTNAME}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/<HDFS_HOST>/${HDFS_HOST}/g" $HADOOP_HOME/etc/hadoop/core-site.xml
echo "yarn resoucemanager start.."

$HADOOP_HOME/bin/yarn --config $HADOOP_HOME/etc/hadoop nodemanager 

