# k8s-hadoop

Deploy Apache-Hadoop on kubernetes, I will record some problem with issues while doing the project.

## Target

* ResourceManager and NodeManager will be running with docker on k8s.
* HDFS will be runing on Physical machine, and not the same host with RM&&NM.

## RoadMap

Task | Progress
----- | --------
deploy hadoop cluster with docker image | DOING
dploy k8s with local cluster | DONE
deploy dns service on k8s | DONE
deploy hadoop image on k8 | DOING
Runing a mapreducer job | TODO 
