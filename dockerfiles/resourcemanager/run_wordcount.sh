#!/bin/bash

# test the hadoop cluster by running wordcount

# create input files
mkdir input
echo "Hello Docker" >input/file2.txt
echo "Hello Hadoop" >input/file1.txt

# create input directory on HDFS
hadoop fs -mkdir -p /xu.yan/input

# put input files to HDFS
hdfs dfs -put ./input/* /xu.yan/input

# run wordcount
hadoop jar $hadoops/hadoop/share/hadoop/mapreduce/sources/hadoop-mapreduce-examples-2.6.4-sources.jar org.apache.hadoop.examples.WordCount /xu.yan/input /xu.yan/output

# print the input files
echo -e "\ninput file1.txt:"
hdfs dfs -cat input/file1.txt

echo -e "\ninput file2.txt:"
hdfs dfs -cat input/file2.txt

# print the output of wordcount
echo -e "\nwordcount output:"
hdfs dfs -cat output/part-r-00000
